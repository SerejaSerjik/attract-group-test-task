import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class PopulateRealmDatabaseUseCase {
  final ImageRepository repository;

  PopulateRealmDatabaseUseCase(this.repository);

  Future<Either<Failure, Unit>> call({int imageCount = 100}) async {
    // Populate database by fetching and caching images to reach ~900MB for testing cache overflow
    const int targetCacheSizeBytes = 900 * 1024 * 1024; // 900MB

    // Try to get initial cache size, but continue with 0 if database not ready
    int currentCacheSize = 0;
    try {
      final initialCacheSizeResult = await repository.getCacheSize();
      initialCacheSizeResult.fold((failure) => currentCacheSize = 0, (size) => currentCacheSize = size);
    } catch (e) {
      // If cache size is not available, continue with 0
      currentCacheSize = 0;
    }
    int imagesProcessed = 0;

    // Keep fetching and caching images until we reach ~900MB
    while (currentCacheSize < targetCacheSizeBytes && imagesProcessed < imageCount) {
      // Fetch a batch of images
      final imagesResult = await repository.getImages(page: imagesProcessed ~/ 30 + 1, limit: 30);

      final images = imagesResult.fold((failure) {
        // If we can't fetch more images, break the loop
        return <dynamic>[];
      }, (images) => images);

      if (images.isEmpty) break;

      // Cache each image
      for (final image in images) {
        await repository.cacheImage(image); // We don't check result here for simplicity
        imagesProcessed++;

        // Check cache size after every few images to avoid too many calls
        if (imagesProcessed % 10 == 0) {
          try {
            final cacheSizeResult = await repository.getCacheSize();
            cacheSizeResult.fold(
              (failure) => null, // Continue even if we can't check size
              (newCacheSize) {
                currentCacheSize = newCacheSize;
                if (currentCacheSize >= targetCacheSizeBytes) {
                  return;
                }
              },
            );
          } catch (e) {
            // Continue even if cache size check fails
          }

          if (currentCacheSize >= targetCacheSizeBytes) {
            break;
          }
        }
      }
    }

    // Final cache size check and cleanup if needed
    try {
      final finalCacheSizeResult = await repository.getCacheSize();
      return finalCacheSizeResult.fold((failure) => Left(failure), (finalCacheSize) async {
        if (finalCacheSize >= targetCacheSizeBytes) {
          final clearResult = await repository.clearCacheToLimit(1024 * 1024 * 1024); // 1GB limit
          return clearResult;
        }
        return Right(unit);
      });
    } catch (e) {
      // Return success even if final cache size check fails
      return Right(unit);
    }
  }
}
