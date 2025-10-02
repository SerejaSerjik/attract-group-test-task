import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CacheSizeIndicator extends StatefulWidget {
  const CacheSizeIndicator({super.key});

  @override
  State<CacheSizeIndicator> createState() => _CacheSizeIndicatorState();
}

class _CacheSizeIndicatorState extends State<CacheSizeIndicator> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  int _previousCacheSize = 0;
  bool _showChangeIndicator = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for breathing effect
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Scale animation for cache changes
    _scaleController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onCacheSizeChanged(int newSize) {
    if (_previousCacheSize != newSize) {
      final change = newSize - _previousCacheSize;
      final changeMB = (change / (1024 * 1024)).toStringAsFixed(1);
      final newSizeMB = (newSize / (1024 * 1024)).toStringAsFixed(1);

      log(
        '🎯 CACHE INDICATOR: Size changed from $_previousCacheSize to $newSize bytes (${change > 0 ? '+' : ''}$changeMB MB)',
        name: 'CacheSizeIndicator',
      );

      _showChangeIndicator = true;
      _scaleController.forward(from: 0.0).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showChangeIndicator = false);
          }
        });
      });
      _previousCacheSize = newSize;

      log('✨ CACHE INDICATOR: Animation triggered, new cache size: $newSizeMB MB', name: 'CacheSizeIndicator');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageGalleryCubit, ImageGalleryState>(
      buildWhen: (previous, current) {
        // Rebuild on cache size updates and state changes that might affect cache size
        if (current is ImageGalleryCacheSizeUpdated) return true;
        if (current is ImageGalleryLoaded) return true;
        if (current is ImageGalleryLoadingMore) return true;
        if (current is ImageGalleryLoading) return true;
        // Always rebuild for now to catch all cache size changes
        return true;
      },
      builder: (context, state) {
        final cubit = context.read<ImageGalleryCubit>();

        // Get cache size from state or fallback to cubit
        int cacheSizeBytes = cubit.cacheSizeBytes;
        if (state is ImageGalleryLoaded) {
          cacheSizeBytes = state.cacheSizeBytes;
        } else if (state is ImageGalleryLoadingMore) {
          cacheSizeBytes = state.cacheSizeBytes;
        } else if (state is ImageGalleryCacheSizeUpdated) {
          cacheSizeBytes = state.cacheSizeBytes;
        }

        // Get cache history from state or fallback to cubit
        List<dynamic> cacheHistory = cubit.cacheHistory;
        if (state is ImageGalleryCacheSizeUpdated) {
          cacheHistory = state.cacheHistory;
        }

        // Логируем текущий размер кэша при каждом билде
        final cacheSizeMB = (cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        log(
          '📊 CACHE INDICATOR: Building with cache size ${cacheSizeMB}MB ($cacheSizeBytes bytes), state: ${state.runtimeType}',
          name: 'CacheSizeIndicator',
        );

        // Trigger change animation
        _onCacheSizeChanged(cacheSizeBytes);

        // Debug logging for cache size changes from history
        if (cacheHistory.isNotEmpty && cacheHistory.length > 1) {
          final lastEntry = cacheHistory.last;
          final prevEntry = cacheHistory[cacheHistory.length - 2];
          final change = lastEntry.sizeBytes - prevEntry.sizeBytes;
          if (change != 0) {
            final changeSign = change > 0 ? '+' : '';
            final changeMB = (change.abs() / (1024 * 1024)).toStringAsFixed(1);
            final direction = change > 0 ? 'increased' : 'decreased';
            log(
              '🔄 CACHE INDICATOR: Cache size $direction by ${changeSign}${changeMB}MB - Current: $lastEntry.formattedSize',
              name: 'CacheSizeIndicator',
            );
          }
        } else {
          log(
            '📋 CACHE INDICATOR: Cache history empty or has only 1 entry (length: ${cacheHistory.length})',
            name: 'CacheSizeIndicator',
          );
        }

        // Return the indicator widget (no longer tappable)
        return _buildIndicatorWidget(context, cubit, cacheSizeBytes, cacheHistory);
      },
    );
  }

  Widget _buildIndicatorWidget(
    BuildContext context,
    ImageGalleryCubit cubit,
    int cacheSizeBytes,
    List<dynamic> cacheHistory,
  ) {
    final cacheSizeMB = (cacheSizeBytes / (1024 * 1024));
    final maxCacheMB = 1024.0; // 1GB limit
    final usagePercentage = (cacheSizeMB / maxCacheMB).clamp(0.0, 1.0);

    log(
      '🎨 CACHE INDICATOR: Building widget - Size: ${cacheSizeMB.toStringAsFixed(1)}MB, Usage: ${(usagePercentage * 100).toInt()}%, History entries: ${cacheHistory.length}',
      name: 'CacheSizeIndicator',
    );

    // Calculate color based on cache usage
    Color indicatorColor;
    if (usagePercentage > 0.9) {
      indicatorColor = Colors.red;
    } else if (usagePercentage > 0.75) {
      indicatorColor = Colors.orange;
    } else if (usagePercentage > 0.6) {
      indicatorColor = Colors.yellow[700]!;
    } else if (usagePercentage > 0.3) {
      indicatorColor = Colors.blue;
    } else {
      indicatorColor = Colors.green;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _showChangeIndicator ? _scaleAnimation.value : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cache size in MB
              Text(
                '${cacheSizeMB.toStringAsFixed(1)}MB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: indicatorColor,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(width: 6),

              // Usage percentage bar
              SizedBox(
                width: 60,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: usagePercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Usage percentage text
              Text(
                '${(usagePercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: indicatorColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
