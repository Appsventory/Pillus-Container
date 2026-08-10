enum ServerStatus { online, offline, connecting, error }

class ServerModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final ServerStatus status;

  /// Hasil quick-check (TCP connect ke port SSH), bukan sesi SSH beneran.
  /// null = belum dicek, true/false = hasil cek terakhir.
  final bool? reachable;

  // Info server (data TERAKHIR yang berhasil diambil - bisa "basi" kalau
  // belum reconnect, makanya selalu tampilin lastConnected biar jelas).
  final String? osInfo;
  final String? dockerVersion;
  final int? containerRunning;
  final int? containerTotal;
  final int? imageCount;
  final double? cpuUsagePercent;
  final double? ramUsagePercent;
  final double? diskUsagePercent;

  // Info client (device yang connect)
  final DateTime? lastConnected;
  final int? latencyMs;

  const ServerModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.status = ServerStatus.offline,
    this.reachable,
    this.osInfo,
    this.dockerVersion,
    this.containerRunning,
    this.containerTotal,
    this.imageCount,
    this.cpuUsagePercent,
    this.ramUsagePercent,
    this.diskUsagePercent,
    this.lastConnected,
    this.latencyMs,
  });

  ServerModel copyWith({
    ServerStatus? status,
    bool? reachable,
    String? osInfo,
    String? dockerVersion,
    int? containerRunning,
    int? containerTotal,
    int? imageCount,
    double? cpuUsagePercent,
    double? ramUsagePercent,
    double? diskUsagePercent,
    DateTime? lastConnected,
    int? latencyMs,
  }) {
    return ServerModel(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      status: status ?? this.status,
      reachable: reachable ?? this.reachable,
      osInfo: osInfo ?? this.osInfo,
      dockerVersion: dockerVersion ?? this.dockerVersion,
      containerRunning: containerRunning ?? this.containerRunning,
      containerTotal: containerTotal ?? this.containerTotal,
      imageCount: imageCount ?? this.imageCount,
      cpuUsagePercent: cpuUsagePercent ?? this.cpuUsagePercent,
      ramUsagePercent: ramUsagePercent ?? this.ramUsagePercent,
      diskUsagePercent: diskUsagePercent ?? this.diskUsagePercent,
      lastConnected: lastConnected ?? this.lastConnected,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  /// Data statis + snapshot stats terakhir, disimpan persisten biar dashboard
  /// bisa langsung nampilin "data terakhir" tanpa perlu SSH connect dulu.
  /// `status` & `reachable` sengaja TIDAK disimpan - itu selalu dihitung
  /// ulang tiap app dibuka (gak relevan lagi kalau app abis di-restart).
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
    'osInfo': osInfo,
    'dockerVersion': dockerVersion,
    'containerRunning': containerRunning,
    'containerTotal': containerTotal,
    'imageCount': imageCount,
    'cpuUsagePercent': cpuUsagePercent,
    'ramUsagePercent': ramUsagePercent,
    'diskUsagePercent': diskUsagePercent,
    'lastConnected': lastConnected?.toIso8601String(),
    'latencyMs': latencyMs,
  };

  factory ServerModel.fromMap(Map<String, dynamic> map) => ServerModel(
    id: map['id'] as String,
    name: map['name'] as String,
    host: map['host'] as String,
    port: map['port'] as int,
    username: map['username'] as String,
    osInfo: map['osInfo'] as String?,
    dockerVersion: map['dockerVersion'] as String?,
    containerRunning: map['containerRunning'] as int?,
    containerTotal: map['containerTotal'] as int?,
    imageCount: map['imageCount'] as int?,
    cpuUsagePercent: (map['cpuUsagePercent'] as num?)?.toDouble(),
    ramUsagePercent: (map['ramUsagePercent'] as num?)?.toDouble(),
    diskUsagePercent: (map['diskUsagePercent'] as num?)?.toDouble(),
    lastConnected: map['lastConnected'] != null
        ? DateTime.tryParse(map['lastConnected'] as String)
        : null,
    latencyMs: map['latencyMs'] as int?,
  );
}
