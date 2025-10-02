class ImageDto {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String title;
  final String? cachedPath;
  final DateTime? cachedAt;
  final int? fileSize;

  ImageDto({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.title,
    this.cachedPath,
    this.cachedAt,
    this.fileSize,
  });

  factory ImageDto.fromJson(Map<String, dynamic> json) {
    return ImageDto(
      id: json['id'].toString(),
      url: json['download_url'] ?? '',
      thumbnailUrl: json['download_url'] ?? '',
      title: 'Image ${json['id']}',
      cachedPath: json['cachedPath'],
      cachedAt: json['cachedAt'] != null ? DateTime.parse(json['cachedAt']) : null,
      fileSize: json['fileSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'cachedPath': cachedPath,
      'cachedAt': cachedAt?.toIso8601String(),
      'fileSize': fileSize,
    };
  }
}
