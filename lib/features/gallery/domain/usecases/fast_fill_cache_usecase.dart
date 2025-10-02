import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

@LazySingleton()
class FastFillCacheUseCase {
  final CacheManagerService cacheManager;

  FastFillCacheUseCase(this.cacheManager);

  /// Estimate available disk space by trying to create small test files
  Future<int> _getAvailableDiskSpace(Directory cacheDir) async {
    int availableBytes = 0;
    const int testFileSize = 1 * 1024 * 1024; // 1MB test files (smaller)
    const int maxTestFiles = 50; // Test up to 50MB

    try {
      for (int i = 0; i < maxTestFiles; i++) {
        final testFile = File(path.join(cacheDir.path, 'space_test_$i.tmp'));
        final testData = Uint8List(testFileSize);

        // Fill with simple pattern (faster than random)
        for (int j = 0; j < testFileSize; j++) {
          testData[j] = (j % 256);
        }

        try {
          await testFile.writeAsBytes(testData);
          availableBytes += testFileSize;

          // Clean up test file immediately
          await testFile.delete();
        } catch (e) {
          // No more space available
          dev.log('⚠️ [FastFillCache] Disk space test failed at ${i + 1}MB: $e', name: 'FastFillCacheUseCase');
          break;
        }
      }
    } catch (e) {
      dev.log('⚠️ [FastFillCache] Error testing disk space: $e', name: 'FastFillCacheUseCase');
    }

    dev.log(
      '💾 [FastFillCache] Disk space estimation completed: ${availableBytes ~/ (1024 * 1024)}MB available',
      name: 'FastFillCacheUseCase',
    );
    return availableBytes;
  }

  Future<Either<Failure, Unit>> call() async {
    try {
      const int targetCacheSizeBytes = 200 * 1024 * 1024; // 200MB (reasonable for testing)
      const int fakeImageSizeBytes = 512 * 1024; // 512KB per fake image (more files for LRU testing)
      const int imagesNeeded = targetCacheSizeBytes ~/ fakeImageSizeBytes; // ~400 images

      // Check available disk space before starting
      try {
        final cacheDir = await cacheManager.getCacheDirectory();
        if (cacheDir != null) {
          // Get available space on the filesystem containing cache directory
          final availableSpace = await _getAvailableDiskSpace(cacheDir);
          final availableMB = availableSpace ~/ (1024 * 1024);

          dev.log(
            '💾 [FastFillCache] Estimated available disk space: ${availableMB}MB, Target: ${targetCacheSizeBytes ~/ (1024 * 1024)}MB',
            name: 'FastFillCacheUseCase',
          );

          // Allow operation to proceed but warn if space is limited
          if (availableSpace < targetCacheSizeBytes + 50 * 1024 * 1024) {
            // 50MB buffer is enough
            final maxPossibleMB = (availableSpace - 50 * 1024 * 1024) ~/ (1024 * 1024);
            if (maxPossibleMB <= 0) {
              return Left(
                UnknownFailure(
                  'Insufficient disk space. Estimated available: ${availableMB}MB, Required: ${targetCacheSizeBytes ~/ (1024 * 1024)}MB. '
                  'Please free up some space on your device.',
                ),
              );
            } else {
              // Warn but allow to proceed with reduced target
              dev.log(
                '⚠️ [FastFillCache] Limited space detected. Will fill up to ${maxPossibleMB}MB instead of target ${targetCacheSizeBytes ~/ (1024 * 1024)}MB',
                name: 'FastFillCacheUseCase',
              );
            }
          }
        }
      } catch (e) {
        dev.log('⚠️ [FastFillCache] Could not check disk space: $e', name: 'FastFillCacheUseCase');
        // Continue anyway, but warn user
      }

      dev.log(
        '🚀 [FastFillCache] Starting fast cache fill to ${targetCacheSizeBytes ~/ (1024 * 1024)}MB with $imagesNeeded fake images',
        name: 'FastFillCacheUseCase',
      );

      // Generate and cache fake images directly to file system
      for (int i = 0; i < imagesNeeded; i++) {
        final imageId = 'fake_${i.toString().padLeft(6, '0')}';

        // Create fake URL for caching
        final fakeUrl = 'https://fake-cache-fill.example.com/$imageId.jpg';

        // Generate fake image data (random bytes)
        final random = Random();
        final fakeImageData = Uint8List(fakeImageSizeBytes);
        for (int j = 0; j < fakeImageSizeBytes; j++) {
          fakeImageData[j] = random.nextInt(256);
        }

        // Get cache directory and create file directly
        final cacheDir = await cacheManager.getCacheDirectory();
        if (cacheDir == null) {
          throw Exception('Cache directory not available');
        }

        final fileName = '${fakeUrl.hashCode.toString()}.jpg';
        final filePath = path.join(cacheDir.path, fileName);
        final file = File(filePath);

        // Create parent directory if needed
        final parentDir = file.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }

        // Write fake data to file
        try {
          await file.writeAsBytes(fakeImageData);
        } catch (e) {
          if (e.toString().contains('No space left on device')) {
            dev.log('💾 [FastFillCache] Disk full at ${i + 1} images. Stopping early.', name: 'FastFillCacheUseCase');
            break; // Stop if disk is full
          }
          rethrow; // Re-throw other errors
        }

        // Update file modification time for LRU
        await file.setLastModified(DateTime.now());

        // Check progress every 50 images
        if (i % 50 == 0) {
          try {
            final currentSize = await cacheManager.getCacheSize();
            final progress = ((i + 1) / imagesNeeded * 100).toStringAsFixed(1);
            dev.log(
              '📊 [FastFillCache] Progress: ${progress}% ($i/${imagesNeeded}) - Cache size: ${(currentSize / (1024 * 1024)).toStringAsFixed(1)}MB',
              name: 'FastFillCacheUseCase',
            );

            if (currentSize >= targetCacheSizeBytes) {
              dev.log(
                '🎯 [FastFillCache] Target size reached: ${(currentSize / (1024 * 1024)).toStringAsFixed(1)}MB',
                name: 'FastFillCacheUseCase',
              );
              break; // Target reached
            }
          } catch (e) {
            dev.log('⚠️ [FastFillCache] Cache size check failed: $e', name: 'FastFillCacheUseCase');
          }
        }
      }

      // Final cleanup: trim to 1GB limit if exceeded
      try {
        final finalSize = await cacheManager.getCacheSize();
        dev.log(
          '🏁 [FastFillCache] Final cache size: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          name: 'FastFillCacheUseCase',
        );

        if (finalSize >= targetCacheSizeBytes) {
          dev.log('🧹 [FastFillCache] Running cleanup to 1GB limit', name: 'FastFillCacheUseCase');
          await cacheManager.cleanup(maxSizeBytes: 1024 * 1024 * 1024); // 1GB
        }
      } catch (e) {
        dev.log('⚠️ [FastFillCache] Final cleanup failed: $e', name: 'FastFillCacheUseCase');
      }

      dev.log('✅ [FastFillCache] Fast cache fill completed successfully', name: 'FastFillCacheUseCase');
      return const Right(unit);
    } catch (e) {
      dev.log('❌ [FastFillCache] Fast cache fill failed: $e', name: 'FastFillCacheUseCase');
      return Left(UnknownFailure('Fast cache fill failed: $e'));
    }
  }
}
