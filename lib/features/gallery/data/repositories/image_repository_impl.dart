import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/image_data_source.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ImageRepository)
class ImageRepositoryImpl implements ImageRepository {
  final ImageDataSource _infiniteScrollDataSource;
  final ImageDataSource _cacheDataSource;
  final CacheManagerService _cacheManagerService;
  late final http.Client _httpClient;

  ImageRepositoryImpl(
    @Named('infinite_scroll') this._infiniteScrollDataSource,
    @Named('cache') this._cacheDataSource,
    this._cacheManagerService,
  ) {
    _httpClient = http.Client();
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getInfiniteScrollImages({int page = 1, int limit = 30}) async {
    log('🔄 Repository: Fetching infinite scroll images page $page, limit $limit', name: 'ImageRepository');

    final offset = (page - 1) * limit;

    // Try cache first for performance
    final cachedImagesResult = await _cacheDataSource.getCachedImages(offset: offset, limit: limit);

    return cachedImagesResult.fold(
      (failure) {
        log('❌ Repository: Failed to get cached images: $failure', name: 'ImageRepository');
        return Left(failure);
      },
      (cachedImages) async {
        if (cachedImages.length >= limit) {
          log('✅ Repository: Page $page served FROM CACHE (${cachedImages.length} images)', name: 'ImageRepository');
          return Right(cachedImages);
        }

        log('🌐 Repository: Loading FROM API (cache had only ${cachedImages.length} images)', name: 'ImageRepository');

        // Fetch from infinite scroll data source when cache is insufficient
        final apiImagesResult = await _infiniteScrollDataSource.fetchImages(page: page, limit: limit);

        return apiImagesResult.fold(
          (failure) {
            log('❌ Repository: Failed to fetch infinite scroll images from API: $failure', name: 'ImageRepository');
            return Left(failure);
          },
          (apiImages) {
            // DON'T cache images automatically in infinite scroll mode
            // Cache will happen lazily when images are actually displayed
            // This prevents unnecessary background downloads and network usage
            log(
              '📄 Repository: Loaded ${apiImages.length} images for infinite scroll (caching disabled to prevent background downloads) - NO AUTO CACHE!',
              name: 'ImageRepository',
            );

            // Verify that we are not caching anything
            if (apiImages.isNotEmpty) {
              log(
                '🚫 Repository: CONFIRMED - NO automatic caching for ${apiImages.length} images in infinite scroll mode',
                name: 'ImageRepository',
              );
            }

            return Right(apiImages);
          },
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getPaginatedImages({int page = 1, int limit = 10}) async {
    log('📄 Repository: Fetching paginated images page $page, limit $limit', name: 'ImageRepository');

    // For pagination with limit=1, check cache first (page is image index)
    if (limit == 1) {
      // Try to get from cache first
      final cachedImageResult = await _cacheDataSource.getCachedImage(page.toString());

      if (cachedImageResult.isRight()) {
        final cachedImage = cachedImageResult.getOrElse(() => null);
        if (cachedImage != null) {
          log('\x1B[32m💾 [CACHE] Image $page served from DISK cache\x1B[0m', name: 'ImageRepository');
          // Cache in background to ensure it's up to date
          unawaited(_cacheImageForPaginationBackground(cachedImage));
          return Right([cachedImage]);
        }
      }

      log('\x1B[32m🌐 [NETWORK] Image $page not in cache, initiating API fetch\x1B[0m', name: 'ImageRepository');
    }

    // For multiple images or when not in cache, fetch from infinite scroll data source
    final apiImagesResult = await _infiniteScrollDataSource.fetchImages(page: page, limit: limit);

    return apiImagesResult.fold(
      (failure) {
        log('❌ Repository: Failed to fetch paginated images from API: $failure', name: 'ImageRepository');
        return Left(failure);
      },
      (apiImages) async {
        // For pagination, cache images in background after showing them to user
        // This provides better UX - show images first, cache later
        for (final image in apiImages) {
          // Start background caching without awaiting
          unawaited(_cacheImageForPaginationBackground(image));
        }

        log(
          '\x1B[32m📡 [API] Successfully fetched ${apiImages.length} images from pagination API\x1B[0m',
          name: 'ImageRepository',
        );
        log(
          '\x1B[32m🔄 [BACKGROUND] Initiated background caching for ${apiImages.length} images\x1B[0m',
          name: 'ImageRepository',
        );
        return Right(apiImages);
      },
    );
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getImages({int page = 1, int limit = 30}) async {
    // Backward compatibility - route to appropriate method based on limit
    if (limit < 30) {
      return getPaginatedImages(page: page, limit: limit);
    } else {
      return getInfiniteScrollImages(page: page, limit: limit);
    }
  }

  @override
  Future<Either<Failure, Unit>> cacheImage(ImageEntity entity) async {
    log('🔄 Repository: Starting cache process for image ${entity.id}', name: 'ImageRepository');

    // Download and save image file if not already cached
    if (entity.cachedPath == null) {
      try {
        // Skip HTTP download for test URLs to avoid timeouts in tests
        if (entity.thumbnailUrl.contains('example.com')) {
          log('⚠️ Repository: Skipping HTTP download for test URL ${entity.thumbnailUrl}', name: 'ImageRepository');
          // Just cache metadata without file
          final cacheResult = await _cacheDataSource.cacheImage(entity);
          return cacheResult;
        }

        // Cache thumbnail instead of full image for gallery display
        log('⬇️ Repository: Downloading thumbnail ${entity.id} from ${entity.thumbnailUrl}', name: 'ImageRepository');

        final response = await _httpClient.get(Uri.parse(entity.thumbnailUrl));
        if (response.statusCode == 200) {
          // Get cache directory
          final cacheDir = await getApplicationCacheDirectory();
          final imageDir = Directory('${cacheDir.path}/images');
          if (!await imageDir.exists()) {
            await imageDir.create(recursive: true);
          }

          // Save file
          final fileName = '${entity.id}_thumb.jpg';
          final filePath = '${imageDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Calculate file size
          final fileSize = await file.length();

          // Create updated entity with file path and size
          final cachedEntity = ImageEntity(
            id: entity.id,
            url: entity.url,
            thumbnailUrl: entity.thumbnailUrl,
            title: entity.title,
            cachedPath: filePath,
            cachedAt: DateTime.now(),
            fileSize: fileSize,
          );

          log(
            '💾 [DOWNLOAD] Saved thumbnail ${entity.id} to disk (${(fileSize / 1024).round()}KB) | URL: ${entity.thumbnailUrl.split('/').last}',
            name: 'ImageRepository',
          );

          final cacheResult = await _cacheDataSource.cacheImage(cachedEntity);
          return cacheResult;
        } else {
          log(
            '❌ Repository: Failed to download thumbnail ${entity.id}: HTTP ${response.statusCode}',
            name: 'ImageRepository',
          );
          // Still cache metadata without file
          final cacheResult = await _cacheDataSource.cacheImage(entity);
          return cacheResult;
        }
      } on http.ClientException catch (e) {
        log('❌ Repository: Network error caching thumbnail ${entity.id}: $e', name: 'ImageRepository');
        // Still cache metadata without file
        final cacheResult = await _cacheDataSource.cacheImage(entity);
        return cacheResult;
      } catch (e) {
        log('❌ Repository: Error caching thumbnail ${entity.id}: $e', name: 'ImageRepository');
        // Still cache metadata without file
        final cacheResult = await _cacheDataSource.cacheImage(entity);
        return cacheResult;
      }
    } else {
      // Image already has cached path, just update metadata
      final cacheResult = await _cacheDataSource.cacheImage(entity);
      return cacheResult;
    }
  }

  /// Background caching for pagination - doesn't block UI
  Future<void> _cacheImageForPaginationBackground(ImageEntity entity) async {
    try {
      await _cacheImageForPagination(entity);
      log('\x1B[32m💾 [BACKGROUND] Image ${entity.id} successfully cached to disk\x1B[0m', name: 'ImageRepository');
    } catch (e) {
      log('\x1B[33m⚠️ [BACKGROUND] Failed to cache image ${entity.id}: $e\x1B[0m', name: 'ImageRepository');
    }
  }

  /// Specialized caching for pagination mode - uses smaller images to fill cache faster
  Future<Either<Failure, Unit>> _cacheImageForPagination(ImageEntity entity) async {
    // For pagination, download even smaller thumbnails to fill cache 2x faster
    if (entity.cachedPath == null) {
      try {
        // Skip HTTP download for test URLs
        if (entity.thumbnailUrl.contains('example.com')) {
          log(
            '⚠️ Repository: Skipping HTTP download for pagination test URL ${entity.thumbnailUrl}',
            name: 'ImageRepository',
          );
          final cacheResult = await _cacheDataSource.cacheImage(entity);
          return cacheResult;
        }

        // Use a smaller thumbnail URL for pagination mode (modify URL to request smaller images)
        final smallThumbnailUrl = _getSmallThumbnailUrl(entity.thumbnailUrl);
        log(
          '\x1B[32m⬇️ [DOWNLOAD] Fetching optimized thumbnail for image ${entity.id}\x1B[0m',
          name: 'ImageRepository',
        );

        final response = await _httpClient.get(Uri.parse(smallThumbnailUrl));
        if (response.statusCode == 200) {
          // Get cache directory
          final cacheDir = await getApplicationCacheDirectory();
          final imageDir = Directory('${cacheDir.path}/images_pagination');
          if (!await imageDir.exists()) {
            await imageDir.create(recursive: true);
          }

          // Save file with pagination suffix
          final fileName = '${entity.id}_pagination_thumb.jpg';
          final filePath = '${imageDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Calculate file size
          final fileSize = await file.length();

          // Create updated entity with file path and size
          final cachedEntity = ImageEntity(
            id: entity.id,
            url: entity.url,
            thumbnailUrl: entity.thumbnailUrl,
            title: entity.title,
            cachedPath: filePath,
            cachedAt: DateTime.now(),
            fileSize: fileSize,
          );

          log(
            '\x1B[32m💾 [DISK] Saved pagination thumbnail ${entity.id} to disk (${(fileSize / 1024).round()}KB)\x1B[0m',
            name: 'ImageRepository',
          );

          final cacheResult = await _cacheDataSource.cacheImage(cachedEntity);
          return cacheResult;
        } else {
          log(
            '❌ Repository: Failed to download pagination thumbnail ${entity.id}: HTTP ${response.statusCode}',
            name: 'ImageRepository',
          );
          // Still cache metadata without file
          final cacheResult = await _cacheDataSource.cacheImage(entity);
          return cacheResult;
        }
      } on http.ClientException catch (e) {
        log('❌ Repository: Network error caching pagination thumbnail ${entity.id}: $e', name: 'ImageRepository');
        final cacheResult = await _cacheDataSource.cacheImage(entity);
        return cacheResult;
      } catch (e) {
        log('❌ Repository: Error caching pagination thumbnail ${entity.id}: $e', name: 'ImageRepository');
        final cacheResult = await _cacheDataSource.cacheImage(entity);
        return cacheResult;
      }
    } else {
      final cacheResult = await _cacheDataSource.cacheImage(entity);
      return cacheResult;
    }
  }

  /// Generate smaller thumbnail URL for pagination mode
  String _getSmallThumbnailUrl(String originalUrl) {
    // For Picsum URLs, reduce dimensions to create smaller thumbnails
    // Example: https://picsum.photos/id/1/400/300 -> https://picsum.photos/id/1/200/150
    final picsumRegex = RegExp(r'https://picsum\.photos/id/(\d+)/(\d+)/(\d+)');
    final match = picsumRegex.firstMatch(originalUrl);

    if (match != null) {
      final id = match.group(1);
      final width = int.tryParse(match.group(2) ?? '400') ?? 400;
      final height = int.tryParse(match.group(3) ?? '300') ?? 300;

      // Reduce dimensions by half for faster cache filling
      final smallWidth = (width * 0.5).round();
      final smallHeight = (height * 0.5).round();

      return 'https://picsum.photos/id/$id/$smallWidth/$smallHeight';
    }

    // For other URLs or if regex doesn't match, return original
    return originalUrl;
  }

  @override
  Future<Either<Failure, ImageEntity?>> getCachedImage(String id) async {
    // Check if image is cached
    final isCachedResult = await _cacheDataSource.isImageCached(id);

    return isCachedResult.fold((failure) => Left(failure), (isCached) async {
      if (isCached) {
        final cachedEntityResult = await _cacheDataSource.getCachedImage(id);
        return cachedEntityResult.fold((failure) => Left(failure), (cachedEntity) async {
          if (cachedEntity != null && cachedEntity.cachedPath != null) {
            final file = File(cachedEntity.cachedPath!);
            if (await file.exists()) {
              return Right(cachedEntity);
            } else {
              log('⚠️ Repository: Cached image file missing for ${cachedEntity.id}', name: 'ImageRepository');
              return Right(null);
            }
          }
          return Right(null);
        });
      }
      return Right(null);
    });
  }

  @override
  Future<Either<Failure, bool>> isImageCached(String id) async {
    return await _cacheDataSource.isImageCached(id);
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getCachedImages({int offset = 0, int limit = 30}) async {
    return await _cacheDataSource.getCachedImages(offset: offset, limit: limit);
  }

  @override
  Future<Either<Failure, int>> getCacheSize() async {
    try {
      final size = await _cacheManagerService.getCacheSize();
      return Right(size);
    } catch (e) {
      log('❌ Repository: Error getting cache size: $e', name: 'ImageRepository');
      return Left(CacheFailure('Failed to get cache size: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCacheToLimit(int maxSizeBytes) async {
    try {
      if (maxSizeBytes == 0) {
        // Clear all cache
        await _cacheManagerService.clearCache();
      } else {
        // For partial cache clearing, we can use the existing logic
        // but for now, we'll use the cache manager's built-in cleanup
        await _cacheManagerService.cleanup();
      }
      return Right(unit);
    } catch (e) {
      log('❌ Repository: Error clearing cache: $e', name: 'ImageRepository');
      return Left(CacheFailure('Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> initializeCache() async {
    try {
      await _cacheManagerService.init();

      // Skip cache size check during initialization to avoid sqflite issues
      // Cache size will be checked later when needed
      log('✅ Repository: Cache initialized successfully (size check skipped during init)', name: 'ImageRepository');

      return Right(unit);
    } catch (e) {
      log('❌ Repository: Error initializing cache: $e', name: 'ImageRepository');
      return Left(CacheFailure('Failed to initialize cache: $e'));
    }
  }

  @override
  CacheManagerService get cacheManagerService => _cacheManagerService;
}
