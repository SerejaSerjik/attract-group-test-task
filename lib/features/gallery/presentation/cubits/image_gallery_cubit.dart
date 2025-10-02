import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_infinite_scroll_images_usecase.dart';
import 'package:injectable/injectable.dart';

part 'image_gallery_state.dart';

/// Entry for tracking cache size changes over time - Cubit-style monitoring
class CacheSizeEntry extends Equatable {
  final DateTime timestamp;
  final int sizeBytes;
  final String operation; // e.g., "populate", "clear", "auto_update", "load_images"
  final int? changeBytes; // Size change from previous entry (can be negative)

  const CacheSizeEntry({required this.timestamp, required this.sizeBytes, required this.operation, this.changeBytes});

  double get sizeMB => sizeBytes / (1024 * 1024);
  double get changeMB => changeBytes != null ? changeBytes! / (1024 * 1024) : 0.0;

  String get formattedSize => '${sizeMB.toStringAsFixed(1)}MB';
  String get formattedChange =>
      changeBytes != null ? '${changeMB >= 0 ? '+' : ''}${changeMB.toStringAsFixed(1)}MB' : 'N/A';

  @override
  List<Object?> get props => [timestamp, sizeBytes, operation, changeBytes];
}

@LazySingleton()
class ImageGalleryCubit extends Cubit<ImageGalleryState> {
  final GetInfiniteScrollImagesUseCase _getInfiniteScrollImagesUseCase;
  final ImageRepository _imageRepository;

  ImageGalleryCubit(this._getInfiniteScrollImagesUseCase, this._imageRepository) : super(ImageGalleryInitial()) {
    _initializeCacheSize();
  }

  List<ImageEntity> _images = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  int _cacheSizeBytes = 0;

  // Enhanced cache monitoring like Tony Stark's Cubit
  final List<CacheSizeEntry> _cacheHistory = [];
  static const int _maxHistorySize = 50; // Keep last 50 entries

  // Always use infinite scroll mode

  // Cache size update optimization
  bool _cacheSizeUpdatePending = false;
  DateTime? _lastCacheSizeUpdate;

  List<ImageEntity> get images => _images;
  bool get hasMoreData => _hasMoreData;
  int get cacheSizeBytes => _cacheSizeBytes;
  List<CacheSizeEntry> get cacheHistory => List.unmodifiable(_cacheHistory);

  // Public method to refresh cache size (can be called from other cubits)
  Future<void> refreshCacheSize() async {
    await _updateCacheSize();
  }

  Future<void> loadInitialImages() async {
    log(
      '📄 [Cubit] Starting to load initial images (page 1) in infinite scroll mode | Current cache: ${(_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB',
      name: 'ImageGalleryCubit',
    );

    if (state is ImageGalleryLoading) {
      log('⚠️ [Cubit] Initial load skipped - already loading', name: 'ImageGalleryCubit');
      return;
    }

    if (isClosed) {
      log('⚠️ [Cubit] Initial load skipped - cubit closed', name: 'ImageGalleryCubit');
      return;
    }

    emit(ImageGalleryLoading());
    log('🔄 [Cubit] Emitted loading state for initial page', name: 'ImageGalleryCubit');

    log('🔍 [Cubit] Calling use case to get images for page 1', name: 'ImageGalleryCubit');

    // Always use infinite scroll
    final result = await _getInfiniteScrollImagesUseCase(page: 1);

    if (isClosed) {
      log('⚠️ [Cubit] Initial load interrupted - cubit closed', name: 'ImageGalleryCubit');
      return;
    }

    result.fold(
      (failure) {
        log('❌ [Cubit] Initial page load failed: $failure', name: 'ImageGalleryCubit');
        emit(ImageGalleryError(message: _mapFailureToMessage(failure)));
      },
      (newImages) {
        _images = newImages;
        _currentPage = 1;
        _hasMoreData = newImages.isNotEmpty; // Infinite scroll has more data if we got images

        log(
          '✅ [Cubit] Initial page loaded: ${newImages.length} images, hasMoreData: $_hasMoreData',
          name: 'ImageGalleryCubit',
        );
        emit(ImageGalleryLoaded(images: _images, hasMoreData: _hasMoreData, cacheSizeBytes: _cacheSizeBytes));

        // Update cache size after loading images (debounced for performance)
        _updateCacheSize();
      },
    );
  }

  Future<void> loadMoreImages() async {
    // Always works in infinite scroll mode

    final nextPage = _currentPage + 1;
    log(
      '📄 [Cubit] Starting to load more images (page $nextPage) | Current cache: ${(_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB',
      name: 'ImageGalleryCubit',
    );

    if (state is ImageGalleryLoading) {
      log('⚠️ [Cubit] Load more skipped - already loading', name: 'ImageGalleryCubit');
      return;
    }

    if (!_hasMoreData) {
      log('⚠️ [Cubit] Load more skipped - no more data available', name: 'ImageGalleryCubit');
      return;
    }

    if (isClosed) {
      log('⚠️ [Cubit] Load more skipped - cubit closed', name: 'ImageGalleryCubit');
      return;
    }

    emit(ImageGalleryLoadingMore(currentImages: _images, cacheSizeBytes: _cacheSizeBytes));
    log('🔄 [Cubit] Emitted loading more state for page $nextPage', name: 'ImageGalleryCubit');

    log('🔍 [Cubit] Calling use case to get images for page $nextPage', name: 'ImageGalleryCubit');
    final result = await _getInfiniteScrollImagesUseCase(page: nextPage);

    if (isClosed) {
      log('⚠️ [Cubit] Load more interrupted - cubit closed', name: 'ImageGalleryCubit');
      return;
    }

    result.fold(
      (failure) {
        log('❌ [Cubit] Load more failed for page $nextPage: $failure', name: 'ImageGalleryCubit');
        emit(ImageGalleryError(message: _mapFailureToMessage(failure)));
      },
      (newImages) {
        if (newImages.isEmpty) {
          _hasMoreData = false;
          log('ℹ️ [Cubit] Page $nextPage is empty, no more data available', name: 'ImageGalleryCubit');
        } else {
          _images.addAll(newImages);
          _currentPage++;
          log(
            '✅ [Cubit] Page $nextPage loaded: ${newImages.length} images, total images: ${_images.length}',
            name: 'ImageGalleryCubit',
          );
        }

        emit(ImageGalleryLoaded(images: _images, hasMoreData: _hasMoreData, cacheSizeBytes: _cacheSizeBytes));

        // Cache size will be updated automatically by debounced mechanism
      },
    );
  }

  Future<void> clearCache() async {
    log(
      '🗑️ [Cubit] Starting full cache clear operation (current cache: ${(_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB, isClosed: $isClosed)',
      name: 'ImageGalleryCubit',
    );

    if (state is ImageGalleryLoading) {
      log('⚠️ [Cubit] Cache clear skipped - already loading', name: 'ImageGalleryCubit');
      return;
    }

    // Allow cache clearing to proceed even if cubit is closed - this is a critical operation
    if (!isClosed) {
      emit(ImageGalleryLoading());
      log('🔄 [Cubit] Emitted loading state for cache clear', name: 'ImageGalleryCubit');
    } else {
      log('ℹ️ [Cubit] Cubit is closed but proceeding with cache clear operation', name: 'ImageGalleryCubit');
    }

    try {
      log('💾 [Cubit] Calling repository to clear all cache', name: 'ImageGalleryCubit');
      final clearResult = await _imageRepository.clearCacheToLimit(0); // Clear all cache

      clearResult.fold(
        (failure) {
          log('❌ [Cubit] Cache clear failed: $failure', name: 'ImageGalleryCubit');
          if (!isClosed) {
            emit(ImageGalleryError(message: _mapFailureToMessage(failure)));
          }
        },
        (_) async {
          log('🔄 [Cubit] Cache cleared from repository, now updating local cache size', name: 'ImageGalleryCubit');

          // Reset local cache size to 0 immediately
          final oldCacheSize = _cacheSizeBytes;
          _cacheSizeBytes = 0;
          log(
            '📊 [CACHE] Local cache size reset from ${(oldCacheSize / (1024 * 1024)).toStringAsFixed(1)}MB to 0MB',
            name: 'ImageGalleryCubit',
          );

          // Emit cache size update to refresh the indicator immediately
          if (!isClosed) {
            emit(ImageGalleryCacheSizeUpdated(cacheSizeBytes: 0, cacheHistory: _cacheHistory));
          }

          // Reload images after clearing cache, but only if we're in infinite scroll mode
          // Always reload images after cache clear in infinite scroll mode
          await loadInitialImages();

          log('✅ [Cubit] Cache clear operation completed successfully', name: 'ImageGalleryCubit');
        },
      );
    } catch (e) {
      log('❌ [Cubit] Cache clear error: $e', name: 'ImageGalleryCubit');
      if (!isClosed) {
        emit(ImageGalleryError(message: 'Unexpected error during cache clear'));
      }
    }
  }

  // Access to repository for image caching
  ImageRepository get repository => _imageRepository;

  /// Public method to update cache size indicator (used by widgets)
  Future<void> updateCacheSizeIndicator() => _updateCacheSize();

  Future<void> _initializeCacheSize() async {
    log('🔄 [Cubit] Initializing cache size on app startup', name: 'ImageGalleryCubit');
    await _updateCacheSize();
  }

  /// Add cache size entry to history with Cubit-style logging
  void _addCacheHistoryEntry(String operation, int newSize) {
    final previousSize = _cacheHistory.isNotEmpty ? _cacheHistory.last.sizeBytes : 0;
    final change = newSize - previousSize;

    final entry = CacheSizeEntry(
      timestamp: DateTime.now(),
      sizeBytes: newSize,
      operation: operation,
      changeBytes: _cacheHistory.isNotEmpty ? change : null,
    );

    _cacheHistory.add(entry);

    // Keep history size manageable
    if (_cacheHistory.length > _maxHistorySize) {
      _cacheHistory.removeAt(0);
    }

    // Cubit-style logging with detailed cache metrics
    final emoji = change >= 0 ? (change > 0 ? '📈' : '📊') : '📉';
    final changeText = change != 0
        ? ' (${change >= 0 ? '+' : ''}${(change / (1024 * 1024)).toStringAsFixed(1)}MB)'
        : '';

    log(
      '$emoji [Cubit] Cache ${operation.toUpperCase()}: $entry.formattedSize$changeText | Total operations: $_cacheHistory.length',
      name: 'CacheMonitor',
    );

    if (_cacheHistory.length >= 2) {
      final trend = _calculateCacheTrend();
      log(
        '📊 [Cubit] Cache Trend Analysis: $trend | Peak: ${_getPeakCacheSize().formattedSize} | Valley: ${_getMinCacheSize().formattedSize}',
        name: 'CacheMonitor',
      );
    }
  }

  /// Calculate cache size trend over recent history
  String _calculateCacheTrend() {
    if (_cacheHistory.length < 3) return 'Insufficient data';

    final recent = _cacheHistory.sublist(_cacheHistory.length - 3);
    final changes = <double>[];

    for (int i = 1; i < recent.length; i++) {
      final change = recent[i].changeMB;
      changes.add(change);
    }

    final avgChange = changes.reduce((a, b) => a + b) / changes.length;

    if (avgChange > 1.0) return 'Growing rapidly (+${avgChange.toStringAsFixed(1)}MB/operation)';
    if (avgChange > 0.1) return 'Growing steadily (+${avgChange.toStringAsFixed(1)}MB/operation)';
    if (avgChange > -0.1) return 'Stable (${avgChange.toStringAsFixed(1)}MB/operation)';
    if (avgChange > -1.0) return 'Shrinking slowly (${avgChange.toStringAsFixed(1)}MB/operation)';
    return 'Shrinking rapidly (${avgChange.toStringAsFixed(1)}MB/operation)';
  }

  /// Get peak cache size from history
  CacheSizeEntry _getPeakCacheSize() {
    return _cacheHistory.reduce((a, b) => a.sizeBytes > b.sizeBytes ? a : b);
  }

  /// Get minimum cache size from history
  CacheSizeEntry _getMinCacheSize() {
    return _cacheHistory.reduce((a, b) => a.sizeBytes < b.sizeBytes ? a : b);
  }

  /// Optimized cache size update with debouncing to prevent laggy UI updates
  Future<void> _updateCacheSize() async {
    // Prevent multiple simultaneous cache size updates
    if (_cacheSizeUpdatePending) {
      log('⚠️ [Cubit] Cache size update skipped - update already pending', name: 'ImageGalleryCubit');
      return;
    }

    // Debounce updates - don't update more than once every 100ms
    final now = DateTime.now();
    if (_lastCacheSizeUpdate != null && now.difference(_lastCacheSizeUpdate!).inMilliseconds < 100) {
      log('⚠️ [Cubit] Cache size update debounced', name: 'ImageGalleryCubit');
      return;
    }

    _cacheSizeUpdatePending = true;

    try {
      final result = await _imageRepository.getCacheSize();
      result.fold(
        (failure) {
          log('⚠️ [Cubit] Failed to get cache size: $failure', name: 'ImageGalleryCubit');
        },
        (size) {
          final oldSize = _cacheSizeBytes;
          final sizeChange = size - oldSize;
          _cacheSizeBytes = size;
          _lastCacheSizeUpdate = DateTime.now();

          log(
            '📊 [CACHE] Size updated: ${(size / (1024 * 1024)).toStringAsFixed(1)}MB (change: ${sizeChange >= 0 ? '+' : ''}${(sizeChange / (1024 * 1024)).toStringAsFixed(1)}MB)',
            name: 'ImageGalleryCubit',
          );

          // Add to Cubit-style monitoring history
          _addCacheHistoryEntry('auto_update', size);

          // Only emit state change if cache size actually changed or if it's been more than 2 seconds
          final shouldEmit =
              oldSize != size ||
              (_lastCacheSizeUpdate != null && DateTime.now().difference(_lastCacheSizeUpdate!).inSeconds > 2);

          if (shouldEmit && !isClosed) {
            log('🔄 [CACHE] Emitting state update for cache indicator', name: 'ImageGalleryCubit');
            // Emit cache size update state to trigger UI update for cache indicator
            emit(ImageGalleryCacheSizeUpdated(cacheSizeBytes: size, cacheHistory: _cacheHistory));
          } else if (shouldEmit && isClosed) {
            log('⚠️ [CACHE] State update skipped - cubit is closed', name: 'ImageGalleryCubit');
          } else {
            log('⚠️ [CACHE] State update skipped (no significant change)', name: 'ImageGalleryCubit');
          }
        },
      );
    } finally {
      _cacheSizeUpdatePending = false;
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server error: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Network error: ${failure.message}';
    } else if (failure is CacheFailure) {
      return 'Cache error: ${failure.message}';
    } else {
      return 'Unknown error: ${failure.message}';
    }
  }

  // Always operates in infinite scroll mode
}
