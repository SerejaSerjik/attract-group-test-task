import 'package:equatable/equatable.dart';

class ImageEntity extends Equatable {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String title;
  final String? cachedPath;
  final DateTime? cachedAt;
  final int? fileSize;

  const ImageEntity({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.title,
    this.cachedPath,
    this.cachedAt,
    this.fileSize,
  });

  @override
  List<Object?> get props => [id, url, thumbnailUrl, title, cachedPath, cachedAt, fileSize];
}
