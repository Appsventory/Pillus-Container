import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../models/container_model.dart';
import '../models/container_stats_model.dart';
import 'settings_service.dart';

/// Pusat semua koneksi SSH aktif (session pool).
/// Satu server = satu SSHClient yang dipakai ulang terus selama app hidup,
/// jadi gak buka channel baru tiap kali mau ambil data -> hemat resource.
class DockerRepository {
  DockerRepository._();
  static final instance = DockerRepository._();

  final Map<String, SSHClient> _pool = {};

  /// Dipasang sekali dari server_provider.dart. Dipanggil otomatis kalau
  /// ada command yang gagal karena transport SSH mati (network putus
  /// sebentar, app di-background lama, dll) - coba connect ulang diam-diam
  /// pakai kredensial yang udah tersimpan, TANPA nunjukin dialog/error ke
  /// user kecuali reconnect-nya sendiri juga gagal.
  Future<bool> Function(String serverId)? reconnectHandler;

  // --- Stats live: satu proses `docker stats` di-share ke semua listener,
  // otomatis berhenti kalau gak ada yang nonton lagi (hemat resource).
  final Map<String, SSHSession> _statsSessions = {};
  final Map<String, StreamController<Map<String, ContainerStatsModel>>>
  _statsControllers = {};
  final Map<String, Map<String, ContainerStatsModel>> _statsLatest = {};

  /// Path binary docker dari Settings (default "docker").
  String get _d {
    final path = SettingsService.instance.current.dockerCliPath.trim();
    return path.isEmpty ? 'docker' : path;
  }

  // --- Cache TTL singkat buat data list (container/image/volume/network).
  // Tujuannya: kalau user bolak-balik tab dalam beberapa detik, gak perlu
  // SSH round-trip ulang tiap kali. Otomatis kadaluarsa sendiri, dan
  // langsung di-invalidate begitu ada aksi mutasi (start/stop/remove/dll)
  // biar data yang ditampilin gak basi.
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(seconds: 8);

  Future<T> _cached<T>(
    String key,
    bool forceRefresh,
    Future<T> Function() fetch,
  ) async {
    if (!forceRefresh) {
      final entry = _cache[key];
      if (entry != null && DateTime.now().difference(entry.time) < _cacheTtl) {
        return entry.data as T;
      }
    }
    final data = await fetch();
    _cache[key] = _CacheEntry(data, DateTime.now());
    return data;
  }

  void _invalidate(String prefix) {
    _cache.removeWhere((k, _) => k.startsWith(prefix));
  }

  bool isConnected(String serverId) => _pool.containsKey(serverId);

  SSHClient? getClient(String serverId) => _pool[serverId];

  /// Daftarkan/ganti client aktif untuk 1 server. Client lama (kalau ada)
  /// ditutup dulu biar gak ada koneksi nyangkut.
  void registerClient(String serverId, SSHClient client) {
    _pool[serverId]?.close();
    _pool[serverId] = client;
  }

  Future<void> closeClient(String serverId) async {
    await _stopStatsStream(serverId);
    _pool[serverId]?.close();
    _pool.remove(serverId);
    _invalidate(':$serverId');
  }

  void closeAll() {
    for (final id in _statsSessions.keys.toList()) {
      _stopStatsStream(id);
    }
    for (final c in _pool.values) {
      c.close();
    }
    _pool.clear();
  }

  SSHClient _requireClient(String serverId) {
    final client = _pool[serverId];
    if (client == null) {
      throw StateError('Belum ada sesi SSH aktif untuk server ini');
    }
    return client;
  }

  bool _isTransportError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('transport is closed') ||
        s.contains('sshstateerror') ||
        s.contains('connection closed') ||
        s.contains('socket has been closed') ||
        s.contains('channel closed');
  }

  /// Jalanin command lewat SSH, dengan 1x auto-reconnect diam-diam kalau
  /// ternyata transport-nya udah mati. Semua pemanggil command (container
  /// actions, list container/image/volume/network, compose, dll) lewat
  /// sini biar semua kebagian proteksi yang sama.
  Future<List<int>> _runRaw(String serverId, String command) async {
    try {
      final client = _requireClient(serverId);
      return await client.run(command);
    } catch (e) {
      if (_isTransportError(e) && reconnectHandler != null) {
        final reconnected = await reconnectHandler!(serverId);
        if (reconnected) {
          final client = _requireClient(serverId);
          return await client.run(command);
        }
      }
      rethrow;
    }
  }

  /// Ambil daftar container via `docker ps --format json`.
  /// Reuse channel yang udah connect, bukan bikin koneksi baru.
  Future<List<ContainerModel>> listContainers(
    String serverId, {
    bool includeStopped = true,
    bool forceRefresh = false,
  }) {
    return _cached(
      'containers:$serverId:$includeStopped',
      forceRefresh,
      () async {
        final cmd = includeStopped
            ? '$_d ps -a --format "{{json .}}"'
            : '$_d ps --format "{{json .}}"';
        final raw = await _runRaw(serverId, cmd);
        final text = utf8.decode(raw, allowMalformed: true).trim();
        if (text.isEmpty) return <ContainerModel>[];
        return text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map(
              (line) => ContainerModel.fromDockerJson(
                jsonDecode(line) as Map<String, dynamic>,
              ),
            )
            .toList();
      },
    );
  }

  Future<String> _exec(String serverId, String command) async {
    final raw = await _runRaw(serverId, command);
    return utf8.decode(raw, allowMalformed: true).trim();
  }

  Future<void> startContainer(String serverId, String containerId) => _exec(
    serverId,
    '$_d start $containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> stopContainer(String serverId, String containerId) => _exec(
    serverId,
    '$_d stop $containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> restartContainer(String serverId, String containerId) => _exec(
    serverId,
    '$_d restart $containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> pauseContainer(String serverId, String containerId) => _exec(
    serverId,
    '$_d pause $containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> unpauseContainer(String serverId, String containerId) => _exec(
    serverId,
    '$_d unpause $containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> renameContainer(
    String serverId,
    String containerId,
    String newName,
  ) => _exec(
    serverId,
    '$_d rename $containerId $newName',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  Future<void> removeContainer(
    String serverId,
    String containerId, {
    bool force = false,
  }) => _exec(
    serverId,
    '$_d rm ${force ? '-f ' : ''}$containerId',
  ).whenComplete(() => _invalidate('containers:$serverId'));

  /// Create + start container via `docker run -d`.
  /// [ports] format: host:container[/tcp|udp] e.g. 8080:80/tcp
  /// [env] KEY=VALUE
  /// [volumes] host:container[:ro]
  Future<String> createContainer(
    String serverId, {
    required String image,
    String? name,
    String? network,
    String restartPolicy = 'no',
    List<String> ports = const [],
    List<String> env = const [],
    List<String> volumes = const [],
    String? command,
    bool autoRemove = false,
    bool privileged = false,
  }) async {
    final args = <String>[_d, 'run', '-d'];
    if (autoRemove) args.add('--rm');
    if (privileged) args.add('--privileged');
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      args.addAll(['--name', _quote(n)]);
    }
    final net = network?.trim();
    if (net != null && net.isNotEmpty && net != 'bridge') {
      args.addAll(['--network', _quote(net)]);
    }
    final rp = restartPolicy.trim();
    if (rp.isNotEmpty && rp != 'no') {
      args.addAll(['--restart', _quote(rp)]);
    }
    for (final p in ports) {
      final v = p.trim();
      if (v.isEmpty) continue;
      args.addAll(['-p', _quote(v)]);
    }
    for (final e in env) {
      final v = e.trim();
      if (v.isEmpty) continue;
      args.addAll(['-e', _quote(v)]);
    }
    for (final vol in volumes) {
      final v = vol.trim();
      if (v.isEmpty) continue;
      args.addAll(['-v', _quote(v)]);
    }
    args.add(_quote(image.trim()));
    final cmd = command?.trim();
    if (cmd != null && cmd.isNotEmpty) {
      // Append raw command tokens (user responsibility).
      args.add(cmd);
    }
    final out = await _exec(serverId, args.join(' '));
    _invalidate('containers:$serverId');
    return out;
  }

  /// Ambil detail lengkap container via `docker inspect`.
  Future<Map<String, dynamic>> inspectContainer(
    String serverId,
    String containerId,
  ) async {
    final raw = await _exec(serverId, '$_d inspect $containerId');
    final decoded = jsonDecode(raw);
    if (decoded is List && decoded.isNotEmpty) {
      return decoded.first as Map<String, dynamic>;
    }
    throw StateError('Format inspect tidak dikenali');
  }

  /// Ambil log container, [tailLines] batasi jumlah baris terakhir biar
  /// gak nyedot memori kalau containernya berisik.
  Future<String> containerLogs(
    String serverId,
    String containerId, {
    int tailLines = 200,
  }) => _exec(serverId, '$_d logs --tail $tailLines $containerId 2>&1');

  /// Buka sesi shell interaktif (PTY) di host, langsung diarahkan masuk
  /// ke dalam container via `docker exec -it`.
  Future<SSHSession> openExecShell(
    String serverId,
    String containerId, {
    String shellCmd = '/bin/sh',
    int cols = 80,
    int rows = 24,
  }) async {
    final client = _requireClient(serverId);
    final session = await client.shell(
      pty: SSHPtyConfig(width: cols, height: rows),
    );
    session.write(utf8.encode('$_d exec -it $containerId $shellCmd\n'));
    return session;
  }

  // --- Image management ---

  Future<List<Map<String, dynamic>>> listImages(
    String serverId, {
    bool forceRefresh = false,
  }) {
    return _cached('images:$serverId', forceRefresh, () async {
      final raw = await _exec(serverId, '$_d images --format "{{json .}}"');
      if (raw.isEmpty) return <Map<String, dynamic>>[];
      return raw
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
    });
  }

  /// Pull image baru. Ini bisa lama (download), jadi caller sebaiknya
  /// kasih indikator loading yang jelas ke user.
  Future<String> pullImage(String serverId, String imageName) async {
    final name = imageName.trim();
    if (name.isEmpty) {
      throw ArgumentError('Image name empty');
    }
    // Explicit exit code biar gagal (not found / denied) naik ke UI.
    final out = await _exec(
      serverId,
      '$_d pull ${_quote(name)} ; echo __PILLUS_EXIT:\$?',
    );
    final marker = '__PILLUS_EXIT:';
    var code = 0;
    var body = out;
    final idx = out.lastIndexOf(marker);
    if (idx >= 0) {
      body = out.substring(0, idx).trim();
      code = int.tryParse(out.substring(idx + marker.length).trim()) ?? 1;
    }
    _invalidate('images:$serverId');
    if (code != 0) {
      final msg = body.isEmpty ? 'docker pull failed (exit $code)' : body;
      throw StateError(msg);
    }
    return body;
  }

  /// Cari image di Docker Hub (`docker search` di host remote).
  Future<List<Map<String, dynamic>>> searchImages(
    String serverId,
    String query, {
    int limit = 25,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final raw = await _exec(
      serverId,
      '$_d search --limit $limit ${_quote(q)} --format "{{json .}}" 2>/dev/null',
    );
    if (raw.isEmpty) return [];
    final out = <Map<String, dynamic>>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      try {
        out.add(jsonDecode(t) as Map<String, dynamic>);
      } catch (_) {}
    }
    return out;
  }

  /// Build image di remote. Jika [dockerfileContent] diisi, file sementara
  /// dibuat di /tmp lalu di-build. Jika null, pakai [contextPath].
  Future<String> buildImage(
    String serverId, {
    required String name,
    String tag = 'latest',
    String? dockerfileContent,
    String contextPath = '.',
  }) async {
    final imageRef = '$name:$tag';
    if (dockerfileContent != null && dockerfileContent.trim().isNotEmpty) {
      return _buildFromDockerfileContent(serverId, imageRef, dockerfileContent);
    }
    return _exec(
      serverId,
      '$_d build -t ${_quote(imageRef)} ${_quote(contextPath)}',
    ).whenComplete(() => _invalidate('images:$serverId'));
  }

  Future<String> _buildFromDockerfileContent(
    String serverId,
    String imageRef,
    String dockerfileContent,
  ) async {
    final b64 = base64Encode(utf8.encode(dockerfileContent));
    final docker = _d;
    final cmd = StringBuffer()
      ..writeln('set -e')
      ..writeln('DIR=\$(mktemp -d /tmp/pillus-build-XXXXXX)')
      ..writeln("echo '$b64' | base64 -d > \"\$DIR/Dockerfile\"")
      ..writeln('$docker build -t ${_quote(imageRef)} "\$DIR"')
      ..writeln('RC=\$?')
      ..writeln('rm -rf "\$DIR"')
      ..writeln('exit \$RC');
    return _exec(
      serverId,
      cmd.toString(),
    ).whenComplete(() => _invalidate('images:$serverId'));
  }

  Future<void> removeImage(
    String serverId,
    String imageId, {
    bool force = false,
  }) => _exec(
    serverId,
    '$_d rmi ${force ? '-f ' : ''}$imageId',
  ).whenComplete(() => _invalidate('images:$serverId'));

  Future<Map<String, dynamic>> inspectImage(
    String serverId,
    String imageId,
  ) async {
    final raw = await _exec(serverId, '$_d inspect $imageId');
    final decoded = jsonDecode(raw);
    if (decoded is List && decoded.isNotEmpty) {
      return decoded.first as Map<String, dynamic>;
    }
    throw StateError('Format inspect tidak dikenali');
  }

  // --- Volume management ---

  Future<List<Map<String, dynamic>>> listVolumes(
    String serverId, {
    bool forceRefresh = false,
  }) {
    return _cached('volumes:$serverId', forceRefresh, () async {
      final raw = await _exec(serverId, '$_d volume ls --format "{{json .}}"');
      if (raw.isEmpty) return <Map<String, dynamic>>[];
      return raw
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> createVolume(String serverId, String name) => _exec(
    serverId,
    '$_d volume create $name',
  ).whenComplete(() => _invalidate('volumes:$serverId'));

  Future<void> removeVolume(
    String serverId,
    String name, {
    bool force = false,
  }) => _exec(
    serverId,
    '$_d volume rm ${force ? '-f ' : ''}$name',
  ).whenComplete(() => _invalidate('volumes:$serverId'));

  // --- Network management ---

  Future<List<Map<String, dynamic>>> listNetworks(
    String serverId, {
    bool forceRefresh = false,
  }) {
    return _cached('networks:$serverId', forceRefresh, () async {
      final raw = await _exec(serverId, '$_d network ls --format "{{json .}}"');
      if (raw.isEmpty) return <Map<String, dynamic>>[];
      return raw
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> createNetwork(
    String serverId,
    String name, {
    String driver = 'bridge',
  }) => _exec(
    serverId,
    '$_d network create -d $driver $name',
  ).whenComplete(() => _invalidate('networks:$serverId'));

  Future<void> removeNetwork(String serverId, String name) => _exec(
    serverId,
    '$_d network rm $name',
  ).whenComplete(() => _invalidate('networks:$serverId'));

  Future<Map<String, dynamic>> inspectNetwork(
    String serverId,
    String name,
  ) async {
    final raw = await _exec(serverId, '$_d network inspect $name');
    final decoded = jsonDecode(raw);
    if (decoded is List && decoded.isNotEmpty) {
      return decoded.first as Map<String, dynamic>;
    }
    throw StateError('Format inspect tidak dikenali');
  }

  Future<void> connectContainerToNetwork(
    String serverId,
    String networkName,
    String containerId,
  ) => _exec(
    serverId,
    '$_d network connect $networkName $containerId',
  ).whenComplete(() => _invalidate('networks:$serverId'));

  Future<void> disconnectContainerFromNetwork(
    String serverId,
    String networkName,
    String containerId,
  ) => _exec(
    serverId,
    '$_d network disconnect $networkName $containerId',
  ).whenComplete(() => _invalidate('networks:$serverId'));

  // --- Docker Compose ---

  Future<List<Map<String, dynamic>>> listComposeStacks(String serverId) async {
    // Beberapa versi docker compose output-nya array JSON tunggal,
    // versi lain (dan setelah breaking change) jadi NDJSON: satu object
    // per baris. Handle keduanya biar gak error parse.
    final raw = await _exec(serverId, '$_d compose ls --format json');
    if (raw.isEmpty) return [];

    final trimmed = raw.trim();
    if (trimmed.startsWith('[')) {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [decoded as Map<String, dynamic>];
    }

    // NDJSON: satu JSON object per baris
    return trimmed
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  String _quote(String path) => "'${path.replaceAll("'", "'\\''")}'";

  Future<String> composeUp(String serverId, String configFile) =>
      _exec(serverId, '$_d compose -f ${_quote(configFile)} up -d');

  Future<String> composeDown(String serverId, String configFile) =>
      _exec(serverId, '$_d compose -f ${_quote(configFile)} down');

  Future<String> composeRestart(String serverId, String configFile) =>
      _exec(serverId, '$_d compose -f ${_quote(configFile)} restart');

  Future<String> composePull(String serverId, String configFile) =>
      _exec(serverId, '$_d compose -f ${_quote(configFile)} pull');

  Future<String> composeLogs(
    String serverId,
    String configFile, {
    int tailLines = 200,
  }) => _exec(
    serverId,
    '$_d compose -f ${_quote(configFile)} logs --tail $tailLines 2>&1',
  );

  /// Cek server support `docker compose` plugin v2 apa enggak, biar UI
  /// bisa sembunyiin tab Compose kalau gak didukung.
  Future<bool> supportsCompose(String serverId) async {
    try {
      final out = await _exec(
        serverId,
        '$_d compose version >/dev/null 2>&1 && echo OK || echo NO',
      );
      return out.trim() == 'OK';
    } catch (_) {
      return false;
    }
  }

  // --- Terminal host (bukan exec ke container, shell langsung di host) ---

  Future<SSHSession> openHostShell(
    String serverId, {
    int cols = 80,
    int rows = 24,
  }) async {
    final client = _requireClient(serverId);
    return client.shell(
      pty: SSHPtyConfig(width: cols, height: rows),
    );
  }

  /// Stream stats live SEMUA container di 1 server (CPU/RAM/Net/Block/PIDs).
  ///
  /// Cuma buka SATU proses `docker stats` per server, di-share ke semua
  /// yang listen (misalnya 2 layar beda container di server yang sama gak
  /// bikin 2 proses). Proses ditutup otomatis begitu listener terakhir
  /// berhenti nonton -> gak ada polling nyangkut di background.
  Stream<Map<String, ContainerStatsModel>> watchStats(String serverId) {
    final existing = _statsControllers[serverId];
    if (existing != null) return existing.stream;

    late final StreamController<Map<String, ContainerStatsModel>> controller;
    controller = StreamController<Map<String, ContainerStatsModel>>.broadcast(
      onListen: () => _startStatsStream(serverId, controller),
      onCancel: () {
        // Broadcast controller: onCancel dipanggil tiap listener lepas,
        // tapi cuma beneran stop kalau udah gak ada listener sama sekali.
        if (!controller.hasListener) {
          _stopStatsStream(serverId);
        }
      },
    );
    _statsControllers[serverId] = controller;
    return controller.stream;
  }

  Future<void> _startStatsStream(
    String serverId,
    StreamController<Map<String, ContainerStatsModel>> controller,
  ) async {
    if (_statsSessions.containsKey(serverId)) return;

    try {
      final client = _requireClient(serverId);
      final session = await client.execute('$_d stats --format "{{json .}}"');
      _statsSessions[serverId] = session;
      _statsLatest[serverId] = {};

      final buffer = StringBuffer();
      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (chunk) {
              buffer.write(chunk);
              final lines = buffer.toString().split('\n');
              buffer.clear();
              buffer.write(
                lines.removeLast(),
              ); // simpan sisa baris belum lengkap

              for (final line in lines) {
                if (line.trim().isEmpty) continue;
                try {
                  final json = jsonDecode(line) as Map<String, dynamic>;
                  final stat = ContainerStatsModel.fromDockerJson(json);
                  _statsLatest[serverId]?[stat.id] = stat;
                  if (!controller.isClosed) {
                    controller.add(Map.of(_statsLatest[serverId] ?? {}));
                  }
                } catch (_) {
                  // baris rusak/gak lengkap, skip aja
                }
              }
            },
            onDone: () => _statsSessions.remove(serverId),
            onError: (_) => _statsSessions.remove(serverId),
          );
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  Future<void> _stopStatsStream(String serverId) async {
    _statsSessions[serverId]?.close();
    _statsSessions.remove(serverId);
    _statsLatest.remove(serverId);
    final controller = _statsControllers.remove(serverId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime time;
  _CacheEntry(this.data, this.time);
}
