import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';

abstract class ImageDataSource {
  /// Initialize data source (for databases, etc.)
  Future<void> init();

  /// Fetch images from remote source
  Future<Either<Failure, List<ImageEntity>>> fetchImages({int page = 1, int limit = 30});

  /// Cache an image
  Future<Either<Failure, Unit>> cacheImage(ImageEntity image);

  /// Get cached image
  Future<Either<Failure, ImageEntity?>> getCachedImage(String id);

  /// Check if image is cached
  Future<Either<Failure, bool>> isImageCached(String id);

  /// Get cached images with pagination
  Future<Either<Failure, List<ImageEntity>>> getCachedImages({int offset = 0, int limit = 30});

  /// Get total cache size
  Future<Either<Failure, int>> getCacheSize();

  /// Clear cache to limit
  Future<Either<Failure, Unit>> clearCacheToLimit(int maxSizeBytes);
}
