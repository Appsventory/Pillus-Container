class ContainerStatsModel {
  final String id;
  final String name;
  final String cpuPercent;
  final String memUsage;
  final String memPercent;
  final String netIO;
  final String blockIO;
  final String pids;

  const ContainerStatsModel({
    required this.id,
    required this.name,
    required this.cpuPercent,
    required this.memUsage,
    required this.memPercent,
    required this.netIO,
    required this.blockIO,
    required this.pids,
  });

  /// Parsing angka persen "12.34%" -> 12.34 (buat progress bar).
  double get cpuValue =>
      double.tryParse(cpuPercent.replaceAll('%', '').trim()) ?? 0;
  double get memValue =>
      double.tryParse(memPercent.replaceAll('%', '').trim()) ?? 0;

  factory ContainerStatsModel.fromDockerJson(Map<String, dynamic> json) {
    return ContainerStatsModel(
      id: (json['ID'] as String?) ?? '',
      name: (json['Name'] as String?) ?? '',
      cpuPercent: (json['CPUPerc'] as String?) ?? '0.00%',
      memUsage: (json['MemUsage'] as String?) ?? '-',
      memPercent: (json['MemPerc'] as String?) ?? '0.00%',
      netIO: (json['NetIO'] as String?) ?? '-',
      blockIO: (json['BlockIO'] as String?) ?? '-',
      pids: (json['PIDs']?.toString()) ?? '0',
    );
  }
}
