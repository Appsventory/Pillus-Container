class ComposeStackModel {
  final String name;
  final String status;
  final String configFiles;

  const ComposeStackModel({
    required this.name,
    required this.status,
    required this.configFiles,
  });

  /// Ambil file compose PERTAMA aja buat dipakai di command
  /// (`docker compose -f <file>`), soalnya ConfigFiles bisa berisi
  /// beberapa path dipisah koma.
  String get primaryConfigFile => configFiles.split(',').first.trim();

  bool get isRunning => status.toLowerCase().contains('running');

  factory ComposeStackModel.fromDockerJson(Map<String, dynamic> json) {
    return ComposeStackModel(
      name: (json['Name'] as String?) ?? '-',
      status: (json['Status'] as String?) ?? '-',
      configFiles: (json['ConfigFiles'] as String?) ?? '',
    );
  }
}
