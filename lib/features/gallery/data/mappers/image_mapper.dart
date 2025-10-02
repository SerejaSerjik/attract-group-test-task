import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/data/dtos/image_dto.dart';

class ImageMapper {
  static ImageEntity toEntity(ImageDto dto) {
    return ImageEntity(
      id: dto.id,
      url: dto.url,
      thumbnailUrl: dto.thumbnailUrl,
      title: dto.title,
      cachedPath: dto.cachedPath,
      cachedAt: dto.cachedAt,
      fileSize: dto.fileSize,
    );
  }

  static ImageDto toDto(ImageEntity entity) {
    return ImageDto(
      id: entity.id,
      url: entity.url,
      thumbnailUrl: entity.thumbnailUrl,
      title: entity.title,
      cachedPath: entity.cachedPath,
      cachedAt: entity.cachedAt,
      fileSize: entity.fileSize,
    );
  }
}
