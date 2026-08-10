import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';
import '../models/credential_model.dart';
import '../services/ssh_service.dart';
import '../services/secure_storage_service.dart';
import '../services/docker_repository.dart';
import '../services/network_service.dart';

class ServerListNotifier extends Notifier<List<ServerModel>> {
  @override
  List<ServerModel> build() {
    ref.onDispose(() => DockerRepository.instance.closeAll());
    // Sekali pasang: kalau ada command SSH gagal karena transport mati,
    // DockerRepository bakal manggil ini buat connect ulang diam-diam
    // (pakai credential + fingerprint yang udah trusted, gak ada dialog).
    DockerRepository.instance.reconnectHandler = _silentReconnect;
    // Restore daftar server yang udah tersimpan (async, state ke-update
    // begitu selesai baca storage), lanjut cek reachability tiap server.
    _restoreServers();
    return [];
  }

  /// Reconnect tanpa nunjukin dialog fingerprint/error apapun - dipanggil
  /// otomatis dari DockerRepository pas transport mati di tengah pemakaian
  /// (bukan pas user sengaja connect manual). Kalau host belum pernah
  /// di-trust (gak ada fingerprint tersimpan) atau kredensial ilang,
  /// jangan coba diam-diam - biar user yang connect manual biasa.
  Future<bool> _silentReconnect(String id) async {
    ServerModel server;
    try {
      server = state.firstWhere((s) => s.id == id);
    } catch (_) {
      return false;
    }

    final credential = await SecureStorageService.instance.getCredential(id);
    if (credential == null) return false;

    final knownFingerprint = await SecureStorageService.instance
        .getKnownFingerprint(id);
    if (knownFingerprint == null) return false;

    final result = await SshService.instance.connect(
      host: server.host,
      port: server.port,
      username: server.username,
      credential: credential,
      knownFingerprint: knownFingerprint,
    );

    if (!result.success || result.client == null) {
      _setServer(id, (s) => s.copyWith(status: ServerStatus.error));
      return false;
    }

    DockerRepository.instance.registerClient(id, result.client!);
    _setServer(
      id,
      (s) => s.copyWith(status: ServerStatus.online, reachable: true),
    );
    return true;
  }

  Future<void> _restoreServers() async {
    final saved = await SecureStorageService.instance.getServerList();
    if (saved.isEmpty) return;
    state = saved.map((m) => ServerModel.fromMap(m)).toList();
    unawaited(checkAllReachability());
  }

  /// Quick-check semua server (TCP connect ke port SSH, BUKAN login penuh)
  /// buat nampilin titik status di dashboard tanpa perlu auth SSH.
  Future<void> checkAllReachability() async {
    await Future.wait(state.map((s) => _checkReachability(s.id)));
  }

  Future<void> _checkReachability(String id) async {
    final server = state.firstWhere(
      (s) => s.id == id,
      orElse: () => state.first,
    );
    if (server.id != id) return;

    final ok = await NetworkService.isReachable(server.host, server.port);
    _setServer(id, (s) => s.copyWith(reachable: ok));
  }

  Future<void> _persist() async {
    await SecureStorageService.instance.saveServerList(
      state.map((s) => s.toMap()).toList(),
    );
  }

  void _setServer(String id, ServerModel Function(ServerModel) updater) {
    state = [
      for (final s in state)
        if (s.id == id) updater(s) else s,
    ];
  }

  void updateServer(String id, ServerModel Function(ServerModel) updater) {
    _setServer(id, updater);
  }

  /// Hapus server + tutup sesi SSH + hapus credential/fingerprint tersimpan.
  Future<void> removeServer(String id) async {
    await DockerRepository.instance.closeClient(id);
    await SecureStorageService.instance.deleteCredential(id);
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }

  Future<void> connectServer(
    String id, {
    required Future<bool> Function({
      required String host,
      required String? keyType,
      required String? fingerprint,
      required bool changed,
    })
    onFingerprintPrompt,
  }) async {
    final server = state.firstWhere((s) => s.id == id);
    _setServer(id, (s) => s.copyWith(status: ServerStatus.connecting));

    final credential = await SecureStorageService.instance.getCredential(id);
    if (credential == null) {
      _setServer(id, (s) => s.copyWith(status: ServerStatus.error));
      return;
    }

    var knownFingerprint = await SecureStorageService.instance
        .getKnownFingerprint(id);

    final stopwatch = Stopwatch()..start();
    var result = await SshService.instance.connect(
      host: server.host,
      port: server.port,
      username: server.username,
      credential: credential,
      knownFingerprint: knownFingerprint,
    );

    if (result.needsFingerprintConfirm || result.fingerprintChanged) {
      final trusted = await onFingerprintPrompt(
        host: server.host,
        keyType: result.hostKeyType,
        fingerprint: result.fingerprintHex,
        changed: result.fingerprintChanged,
      );

      if (!trusted || result.fingerprintHex == null) {
        _setServer(id, (s) => s.copyWith(status: ServerStatus.error));
        return;
      }

      await SecureStorageService.instance.saveKnownFingerprint(
        id,
        result.fingerprintHex!,
      );
      knownFingerprint = result.fingerprintHex;

      result = await SshService.instance.connect(
        host: server.host,
        port: server.port,
        username: server.username,
        credential: credential,
        knownFingerprint: knownFingerprint,
      );
    }

    stopwatch.stop();

    // Salah password / auth gagal / host unreachable -> jangan disimpan
    // sebagai "berhasil", biarin status error, caller yang mutusin rollback.
    if (!result.success || result.client == null) {
      _setServer(id, (s) => s.copyWith(status: ServerStatus.error));
      return;
    }

    DockerRepository.instance.registerClient(id, result.client!);
    final info = await SshService.instance.fetchServerInfo(result.client!);

    _setServer(
      id,
      (s) => s.copyWith(
        status: ServerStatus.online,
        reachable: true,
        osInfo: info.osInfo,
        dockerVersion: info.dockerVersion,
        containerRunning: info.containerRunning,
        containerTotal: info.containerTotal,
        imageCount: info.imageCount,
        cpuUsagePercent: info.cpuUsagePercent,
        ramUsagePercent: info.ramUsagePercent,
        diskUsagePercent: info.diskUsagePercent,
        lastConnected: DateTime.now(),
        latencyMs: stopwatch.elapsedMilliseconds,
      ),
    );

    // Simpan snapshot terbaru biar dashboard bisa nampilin "data terakhir"
    // lain kali app dibuka, tanpa perlu connect ulang.
    await _persist();
  }

  /// Tambah server baru ATAU, kalau host yang sama udah terdaftar,
  /// update kredensial/host/port/username server itu terus reconnect
  /// (gak bikin entry duplikat).
  ///
  /// Return true kalau akhirnya berhasil connect (online).
  Future<bool> addAndConnect({
    required ServerModel server,
    required CredentialModel credential,
    required Future<bool> Function({
      required String host,
      required String? keyType,
      required String? fingerprint,
      required bool changed,
    })
    onFingerprintPrompt,
  }) async {
    final existing = state
        .where(
          (s) =>
              s.host.trim().toLowerCase() == server.host.trim().toLowerCase(),
        )
        .toList();

    if (existing.isNotEmpty) {
      // Host sama udah ada -> update in-place, bukan nambah baru.
      final existingId = existing.first.id;
      final merged = ServerModel(
        id: existingId,
        name: server.name,
        host: server.host,
        port: server.port,
        username: server.username,
      );
      _setServer(existingId, (_) => merged);
      await SecureStorageService.instance.saveCredential(
        existingId,
        credential,
      );

      await connectServer(existingId, onFingerprintPrompt: onFingerprintPrompt);

      // Simpan perubahan nama/host/port/username-nya walau gagal connect,
      // biar konsisten sama yang user isi barusan.
      await _persist();

      final result = state.firstWhere((s) => s.id == existingId);
      return result.status == ServerStatus.online;
    }

    // Server baru: tambahkan dulu (belum di-persist), coba connect.
    state = [...state, server];
    await SecureStorageService.instance.saveCredential(server.id, credential);
    await connectServer(server.id, onFingerprintPrompt: onFingerprintPrompt);

    final result = state.firstWhere((s) => s.id == server.id);

    if (result.status == ServerStatus.online) {
      await _persist();
      return true;
    }

    // Gagal total (password salah dll) -> rollback, jangan nyangkut di list.
    state = state.where((s) => s.id != server.id).toList();
    await SecureStorageService.instance.deleteCredential(server.id);
    return false;
  }

  /// Update server yang SUDAH ADA (dipakai oleh "Edit Server"), ditarget
  /// pakai [id] - bukan dedup-by-host kayak addAndConnect, karena user
  /// bisa aja lagi ngedit host-nya juga (kalau dedup-by-host dipakai,
  /// server lama yang host-nya udah beda gak bakal ketemu -> malah bikin
  /// entry duplikat baru, bukan update yang lama).
  Future<bool> updateServerAndReconnect({
    required String id,
    required ServerModel updatedInfo,
    required CredentialModel credential,
    required Future<bool> Function({
      required String host,
      required String? keyType,
      required String? fingerprint,
      required bool changed,
    })
    onFingerprintPrompt,
  }) async {
    // Jangan sampai host baru ini kepakai server LAIN (bukan diri sendiri).
    final collision = state.any(
      (s) =>
          s.id != id &&
          s.host.trim().toLowerCase() == updatedInfo.host.trim().toLowerCase(),
    );
    if (collision) return false;

    final merged = ServerModel(
      id: id,
      name: updatedInfo.name,
      host: updatedInfo.host,
      port: updatedInfo.port,
      username: updatedInfo.username,
    );
    _setServer(id, (_) => merged);
    await SecureStorageService.instance.saveCredential(id, credential);

    await connectServer(id, onFingerprintPrompt: onFingerprintPrompt);

    // Simpan perubahan data server-nya walau gagal connect, biar tetap
    // konsisten sama yang barusan diisi user di form edit.
    await _persist();

    final result = state.firstWhere((s) => s.id == id);
    return result.status == ServerStatus.online;
  }
}

final serverListProvider =
    NotifierProvider<ServerListNotifier, List<ServerModel>>(
      ServerListNotifier.new,
    );
