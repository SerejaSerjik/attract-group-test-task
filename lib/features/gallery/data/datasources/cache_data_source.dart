import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/image_data_source.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:injectable/injectable.dart';

/// Real cache data source using flutter_cache_manager
@LazySingleton(as: ImageDataSource)
@Named('cache')
class CacheDataSource implements ImageDataSource {
  final CacheManagerService _cacheManagerService;

  CacheDataSource(this._cacheManagerService);

  @override
  Future<void> init() async {
    log('🎯 CacheDataSource: Initializing real cache with CacheManagerService', name: 'CacheDataSource');
    await _cacheManagerService.init();
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> fetchImages({int page = 1, int limit = 30}) async {
    log('⚠️ CacheDataSource: fetchImages called - cache data source should not fetch images', name: 'CacheDataSource');
    return Left(CacheFailure('Cache data source does not fetch images from network'));
  }

  @override
  Future<Either<Failure, Unit>> cacheImage(ImageEntity image) async {
    try {
      log('💾 CacheDataSource: Caching image ${image.id}: ${image.thumbnailUrl}', name: 'CacheDataSource');

      // Use CacheManagerService to cache the image with metadata
      await _cacheManagerService.getSingleFile(image.thumbnailUrl, imageId: image.id);

      log('✅ CacheDataSource: Successfully cached image ${image.id}', name: 'CacheDataSource');
      return Right(unit);
    } catch (e) {
      log('❌ CacheDataSource: Failed to cache image ${image.id}: $e', name: 'CacheDataSource');
      return Left(CacheFailure('Failed to cache image: $e'));
    }
  }

  @override
  Future<Either<Failure, ImageEntity?>> getCachedImage(String id) async {
    log(
      '🔍 CacheDataSource: getCachedImage called for id $id - not implemented in file-based cache',
      name: 'CacheDataSource',
    );
    // File-based cache doesn't store metadata, return null
    return Right(null);
  }

  @override
  Future<Either<Failure, bool>> isImageCached(String id) async {
    log(
      '🔍 CacheDataSource: isImageCached called for id $id - not implemented in file-based cache',
      name: 'CacheDataSource',
    );
    // File-based cache doesn't track individual images, assume not cached
    return Right(false);
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getCachedImages({int offset = 0, int limit = 30}) async {
    log(
      '🔍 CacheDataSource: getCachedImages called - file-based cache doesn\'t store metadata',
      name: 'CacheDataSource',
    );
    // File-based cache doesn't store metadata, return empty list
    return Right([]);
  }

  @override
  Future<Either<Failure, int>> getCacheSize() async {
    try {
      final size = await _cacheManagerService.getCacheSize();
      log('📊 CacheDataSource: Cache size: ${(size / (1024 * 1024)).toStringAsFixed(1)}MB', name: 'CacheDataSource');
      return Right(size);
    } catch (e) {
      log('❌ CacheDataSource: Error getting cache size: $e', name: 'CacheDataSource');
      return Left(CacheFailure('Failed to get cache size: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCacheToLimit(int maxSizeBytes) async {
    try {
      if (maxSizeBytes == 0) {
        log('🧹 CacheDataSource: Clearing all cache', name: 'CacheDataSource');
        await _cacheManagerService.clearCache();
      } else {
        log('🧽 CacheDataSource: Running cleanup to ${maxSizeBytes ~/ (1024 * 1024)}MB limit', name: 'CacheDataSource');
        await _cacheManagerService.cleanup(maxSizeBytes: maxSizeBytes);
      }
      return Right(unit);
    } catch (e) {
      log('❌ CacheDataSource: Error clearing cache: $e', name: 'CacheDataSource');
      return Left(CacheFailure('Failed to clear cache: $e'));
    }
  }
}
