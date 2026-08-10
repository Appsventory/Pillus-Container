enum ContainerState { running, exited, paused, created, restarting, unknown }

class ContainerModel {
  final String id;
  final String name;
  final String image;
  final String status; // teks asli, mis. "Up 3 hours" / "Exited (0) 2 days ago"
  final ContainerState state;
  final String ports;
  final String createdAt;

  const ContainerModel({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.state,
    required this.ports,
    required this.createdAt,
  });

  bool get isRunning => state == ContainerState.running;

  factory ContainerModel.fromDockerJson(Map<String, dynamic> json) {
    final status = (json['Status'] as String?) ?? '';
    return ContainerModel(
      id: (json['ID'] as String?) ?? '',
      name: (json['Names'] as String?) ?? '',
      image: (json['Image'] as String?) ?? '',
      status: status,
      state: _deriveState(status),
      ports: (json['Ports'] as String?) ?? '',
      createdAt: (json['CreatedAt'] as String?) ?? '',
    );
  }

  static ContainerState _deriveState(String status) {
    final s = status.toLowerCase();
    if (s.startsWith('up')) return ContainerState.running;
    if (s.startsWith('exited')) return ContainerState.exited;
    if (s.startsWith('paused')) return ContainerState.paused;
    if (s.startsWith('created')) return ContainerState.created;
    if (s.startsWith('restarting')) return ContainerState.restarting;
    return ContainerState.unknown;
  }
}
