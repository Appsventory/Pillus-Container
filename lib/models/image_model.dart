class ImageModel {
  final String id;
  final String repository;
  final String tag;
  final String size;
  final String createdSince;

  const ImageModel({
    required this.id,
    required this.repository,
    required this.tag,
    required this.size,
    required this.createdSince,
  });

  String get displayName => tag == '<none>' ? repository : '$repository:$tag';

  factory ImageModel.fromDockerJson(Map<String, dynamic> json) {
    return ImageModel(
      id: (json['ID'] as String?) ?? '',
      repository: (json['Repository'] as String?) ?? '<none>',
      tag: (json['Tag'] as String?) ?? '<none>',
      size: (json['Size'] as String?) ?? '-',
      createdSince: (json['CreatedSince'] as String?) ?? '-',
    );
  }
}
