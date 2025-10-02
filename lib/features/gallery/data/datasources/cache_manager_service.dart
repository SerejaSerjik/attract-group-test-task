import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';

/// Simple file-based image caching service
/// Provides basic caching functionality without external database dependencies
@LazySingleton()
class CacheManagerService {
  Directory? _cacheDir;
  bool _isInitialized = false;
  bool _isCleanupRunning = false;

  /// Initialize cache directory
  Future<void> init() async {
    if (_isInitialized) {
      log('⚠️ CacheManager: Already initialized, skipping', name: 'CacheManager');
      return;
    }

    try {
      // Initialize cache directory
      _cacheDir = await getApplicationDocumentsDirectory();
      final cachePath = path.join(_cacheDir!.path, 'image_cache');

      // Create cache directory if it doesn't exist
      _cacheDir = Directory(cachePath);
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _isInitialized = true;
      log('🎯 CacheManager: Initialized with directory: $cachePath', name: 'CacheManager');
      log('📊 CacheManager: File-based cache manager initialized', name: 'CacheManager');
    } catch (e) {
      log('❌ CacheManager: Failed to initialize: $e', name: 'CacheManager');
      rethrow;
    }
  }

  /// Generate file path for URL (public for internal use)
  String getFilePath(String url) {
    final fileName = url.hashCode.toString() + path.extension(url.split('?').first);
    return path.join(_cacheDir!.path, fileName);
  }

  /// Get cache directory (for internal operations)
  Future<Directory?> getCacheDirectory() async {
    if (!_isInitialized) {
      await init();
    }
    return _cacheDir;
  }

  /// Get cached file for an image URL
  Future<File?> getFileFromCache(String url) async {
    if (!_isInitialized || _cacheDir == null) {
      log('❌ CacheManager: Not initialized, cannot get file from cache', name: 'CacheManager');
      return null;
    }

    final filePath = getFilePath(url);
    final file = File(filePath);

    if (await file.exists()) {
      final length = await file.length();
      log('✅ CacheManager: Cache hit for $url ($length bytes)', name: 'CacheManager');
      return file;
    } else {
      log('❌ CacheManager: Cache miss for $url', name: 'CacheManager');
      return null;
    }
  }

  /// Download and cache image from URL
  Future<File> downloadFile(String url, {String? key, String? imageId}) async {
    if (!_isInitialized || _cacheDir == null) {
      throw Exception('CacheManager not initialized');
    }

    final filePath = getFilePath(url);
    final file = File(filePath);

    try {
      log('⬇️ CacheManager: Downloading $url', name: 'CacheManager');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        // Update file modification time for LRU eviction
        await file.setLastModified(DateTime.now());
        final length = await file.length();
        log('✅ CacheManager: Downloaded ${url.split('/').last} ($length bytes)', name: 'CacheManager');

        // Check if cleanup is needed after successful download (100MB limit for LRU testing)
        final currentSize = await getCacheSize();
        if (currentSize > 100 * 1024 * 1024) {
          // 100MB for LRU testing - original requirement was 1GB
          log('🧽 CacheManager: Cache size exceeded 100MB after download, running cleanup...', name: 'CacheManager');
          await cleanup();
        }

        return file;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ CacheManager: Error downloading $url: $e', name: 'CacheManager');
      rethrow;
    }
  }

  /// Get or download file (main method for getting images)
  Future<File> getSingleFile(String url, {String? key, String? imageId}) async {
    if (!_isInitialized || _cacheDir == null) {
      throw Exception('CacheManager not initialized');
    }

    // Try to get from cache first
    final cachedFile = await getFileFromCache(url);
    if (cachedFile != null) {
      // Update file modification time for LRU eviction (recently accessed)
      await cachedFile.setLastModified(DateTime.now());
      log('✅ CacheManager: Cache hit for $url', name: 'CacheManager');
      return cachedFile;
    }

    // Download if not cached
    return await downloadFile(url, key: key, imageId: imageId);
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (!_isInitialized || _cacheDir == null) {
      log('❌ CacheManager: Not initialized, cannot get cache size', name: 'CacheManager');
      return 0;
    }

    try {
      int totalSize = 0;
      final files = _cacheDir!.listSync(recursive: true);

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      log(
        '📊 CacheManager: Current cache size: ${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB',
        name: 'CacheManager',
      );
      return totalSize;
    } catch (e) {
      log('❌ CacheManager: Error getting cache size: $e', name: 'CacheManager');
      return 0;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (!_isInitialized || _cacheDir == null) {
      log('❌ CacheManager: Not initialized, cannot clear cache', name: 'CacheManager');
      return;
    }

    try {
      log('🧹 CacheManager: Clearing all cache...', name: 'CacheManager');

      // Clear files
      final files = _cacheDir!.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }

      log('✅ CacheManager: Cache cleared successfully', name: 'CacheManager');
    } catch (e) {
      log('❌ CacheManager: Error clearing cache: $e', name: 'CacheManager');
      rethrow;
    }
  }

  /// Remove specific file from cache
  Future<void> removeFile(String url) async {
    if (!_isInitialized || _cacheDir == null) {
      log('❌ CacheManager: Not initialized, cannot remove file', name: 'CacheManager');
      return;
    }

    try {
      final filePath = getFilePath(url);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        log('🗑️ CacheManager: Removed file from cache: $url', name: 'CacheManager');
      }
    } catch (e) {
      log('❌ CacheManager: Error removing file $url: $e', name: 'CacheManager');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final size = await getCacheSize();
      final files = _isInitialized && _cacheDir != null ? _cacheDir!.listSync().whereType<File>().length : 0;

      return {
        'totalSize': size,
        'sizeMB': (size / (1024 * 1024)).toStringAsFixed(1),
        'fileCount': files,
        'cacheLocation': _cacheDir?.path ?? 'not initialized',
      };
    } catch (e) {
      log('❌ CacheManager: Error getting cache stats: $e', name: 'CacheManager');
      return {'error': e.toString()};
    }
  }

  /// Clean up cache files to stay under 100MB limit (LRU - remove oldest files first)
  Future<void> cleanup({int maxSizeBytes = 100 * 1024 * 1024}) async {
    // 100MB for LRU testing - original requirement was 1GB but emulator may have issues
    // Prevent concurrent cleanup operations
    if (_isCleanupRunning) {
      log('⚠️ CacheManager: Cleanup already running, skipping', name: 'CacheManager');
      return;
    }

    if (!_isInitialized || _cacheDir == null) {
      return;
    }

    _isCleanupRunning = true;

    try {
      log(
        '🧽 CacheManager: Running cleanup (max: ${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB)',
        name: 'CacheManager',
      );

      final files = _cacheDir!.listSync(recursive: true).whereType<File>().toList();

      // Sort by last modified time (oldest first)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      int currentSize = await getCacheSize();
      log(
        '📊 CacheManager: Current cache size: ${(currentSize / (1024 * 1024)).toStringAsFixed(1)}MB',
        name: 'CacheManager',
      );

      // Remove oldest files one by one until under limit
      for (final file in files) {
        try {
          // Check if file still exists before trying to delete
          if (await file.exists()) {
            final fileSize = await file.length();
            await file.delete();
            log(
              '🗑️ CacheManager: Removed ${file.path.split('/').last} (${(fileSize / 1024).toStringAsFixed(1)}KB)',
              name: 'CacheManager',
            );

            // Recalculate cache size after each deletion
            currentSize = await getCacheSize();
            log(
              '📊 CacheManager: Cache size after removal: ${(currentSize / (1024 * 1024)).toStringAsFixed(1)}MB',
              name: 'CacheManager',
            );

            // Stop if we're now under the limit
            if (currentSize <= maxSizeBytes) {
              break;
            }
          }
        } catch (e) {
          // Skip files that can't be accessed or deleted
          log('⚠️ CacheManager: Skipping problematic file ${file.path.split('/').last}: $e', name: 'CacheManager');
          continue;
        }
      }

      log(
        '✅ CacheManager: Cleanup completed. New size: ${(currentSize / (1024 * 1024)).toStringAsFixed(1)}MB',
        name: 'CacheManager',
      );
    } catch (e) {
      log('❌ CacheManager: Error during cleanup: $e', name: 'CacheManager');
    } finally {
      _isCleanupRunning = false;
    }
  }

  /// Dispose cache manager
  void dispose() {
    log('🏁 CacheManager: Service disposed', name: 'CacheManager');
  }
}
