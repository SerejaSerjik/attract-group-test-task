import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';

abstract class ImageRepository {
  Future<Either<Failure, List<ImageEntity>>> getImages({int page = 1, int limit = 30});
  Future<Either<Failure, List<ImageEntity>>> getInfiniteScrollImages({int page = 1, int limit = 30});
  Future<Either<Failure, List<ImageEntity>>> getPaginatedImages({int page = 1, int limit = 10});
  Future<Either<Failure, Unit>> cacheImage(ImageEntity image);
  Future<Either<Failure, ImageEntity?>> getCachedImage(String id);
  Future<Either<Failure, bool>> isImageCached(String id);
  Future<Either<Failure, List<ImageEntity>>> getCachedImages({int offset = 0, int limit = 30});
  Future<Either<Failure, int>> getCacheSize();
  Future<Either<Failure, Unit>> clearCacheToLimit(int maxSizeBytes);
  Future<Either<Failure, Unit>> initializeCache();

  CacheManagerService get cacheManagerService;
}
