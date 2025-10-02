import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_gallery/l10n/app_localizations.dart';
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart';
import 'package:flutter_image_gallery/ui/widgets/cache_size_indicator.dart';
import 'package:flutter_image_gallery/ui/widgets/image_grid_item.dart';
import 'package:flutter_image_gallery/ui/widgets/image_shimmer_grid.dart';
import 'package:flutter_image_gallery/ui/widgets/image_shimmer_placeholder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageGalleryCubit>().loadInitialImages();
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      log('📜 [SCROLL] Reached bottom, loading more images...', name: 'HomeScreen');
      context.read<ImageGalleryCubit>().loadMoreImages();
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.clearCacheTitle),
          content: Text(l10n.clearCacheMessage),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _clearFullCache();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.clear),
            ),
          ],
        );
      },
    );
  }

  void _clearFullCache() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      log('🧹 [CACHE] User requested full cache clear', name: 'HomeScreen');

      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cacheClearing), duration: const Duration(seconds: 1)));
      }

      // Clear cache through cubit
      await context.read<ImageGalleryCubit>().clearCache();

      // Show first success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cacheCleared),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Wait a bit and show additional information
      await Future.delayed(const Duration(seconds: 1));

      // Show second Snackbar with additional information
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagesDeletedFromStorage),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      log('✅ [CACHE] Full cache cleared successfully', name: 'HomeScreen');
    } catch (e) {
      log('❌ [CACHE] Error clearing full cache: $e', name: 'HomeScreen');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text('Image Gallery'), const SizedBox(height: 8), const CacheSizeIndicator()],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, size: 20),
            tooltip: 'Clear full cache',
            onPressed: () => _showClearCacheDialog(context),
          ),
        ],
      ),
      body: _buildGallery(),
    );
  }

  Widget _buildGallery() {
    return BlocBuilder<ImageGalleryCubit, ImageGalleryState>(
      builder: (context, state) {
        // Initial loading - show shimmer grid instead of big loader
        if (state is ImageGalleryInitial || (state is ImageGalleryLoading && state is! ImageGalleryLoadingMore)) {
          log('⏳ [GALLERY] Showing initial loading with shimmer grid...', name: 'HomeScreen');
          return Padding(
            padding: const EdgeInsets.all(8),
            child: ImageShimmerGrid(itemCount: 30), // Show 30 shimmer placeholders for initial load
          );
        }

        if (state is ImageGalleryError) {
          log('❌ [GALLERY] Showing error state: ${state.message}', name: 'HomeScreen');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ImageGalleryCubit>().loadInitialImages(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final cubit = context.read<ImageGalleryCubit>();
        final images = cubit.images;
        final hasMoreData = cubit.hasMoreData;

        log(
          '📸 [GALLERY] Building gallery with ${images.length} images, hasMoreData: $hasMoreData',
          name: 'HomeScreen',
        );

        // Calculate shimmer count for loading more
        const shimmerCount = 6; // Show 6 shimmer placeholders when loading more
        final isLoadingMore = hasMoreData && state is ImageGalleryLoadingMore;
        final totalItemCount = images.length + (isLoadingMore ? shimmerCount : 0);

        if (isLoadingMore) {
          log('⏳ [GALLERY] Loading more images, showing $shimmerCount shimmer placeholders', name: 'HomeScreen');
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            // If we're in the shimmer range (loading more)
            if (index >= images.length) {
              // Show shimmer placeholder of the same size as real images
              return const ImageShimmerPlaceholder();
            }

            final image = images[index];
            return ImageGridItem(image: image);
          },
        );
      },
    );
  }
}
