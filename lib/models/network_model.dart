class NetworkModel {
  final String id;
  final String name;
  final String driver;
  final String scope;

  const NetworkModel({
    required this.id,
    required this.name,
    required this.driver,
    required this.scope,
  });

  factory NetworkModel.fromDockerJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: (json['ID'] as String?) ?? '',
      name: (json['Name'] as String?) ?? '-',
      driver: (json['Driver'] as String?) ?? '-',
      scope: (json['Scope'] as String?) ?? '-',
    );
  }

  /// Network bawaan Docker, jangan biarin user hapus ini.
  bool get isBuiltIn => ['bridge', 'host', 'none'].contains(name);
}
