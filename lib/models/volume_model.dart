class VolumeModel {
  final String name;
  final String driver;
  final String scope;

  const VolumeModel({
    required this.name,
    required this.driver,
    required this.scope,
  });

  factory VolumeModel.fromDockerJson(Map<String, dynamic> json) {
    return VolumeModel(
      name: (json['Name'] as String?) ?? '-',
      driver: (json['Driver'] as String?) ?? '-',
      scope: (json['Scope'] as String?) ?? '-',
    );
  }
}
