import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart';
import 'package:flutter_image_gallery/ui/widgets/image_shimmer_placeholder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Custom image widget with manual caching using file-based caching
/// Provides image loading and caching without external dependencies
class ImageGridItem extends StatefulWidget {
  final ImageEntity image;

  const ImageGridItem({super.key, required this.image});

  @override
  State<ImageGridItem> createState() => _ImageGridItemState();
}

class _ImageGridItemState extends State<ImageGridItem> {
  File? _cachedImageFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.id != widget.image.id) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final cacheManager = context.read<ImageGalleryCubit>().repository.cacheManagerService;
      final file = await cacheManager.getSingleFile(widget.image.thumbnailUrl);

      if (mounted) {
        setState(() {
          _cachedImageFile = file;
          _isLoading = false;
        });
        log('✅ [ImageWidget-${widget.image.id}] Image loaded and cached successfully', name: 'ImageGridItem');

        // Update cache size indicator after successful image loading/caching
        if (mounted) {
          context.read<ImageGalleryCubit>().updateCacheSizeIndicator();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        log('❌ [ImageWidget-${widget.image.id}] Image load error: $e', name: 'ImageGridItem');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImageContent()),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_hasError || _cachedImageFile == null) {
      return Container(
        color: Colors.grey[300],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Check if cached file still exists (might have been deleted during cache clear)
    if (!_cachedImageFile!.existsSync()) {
      log('⚠️ [ImageWidget-${widget.image.id}] Cached file no longer exists, reloading...', name: 'ImageGridItem');
      // Reset state and reload image
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _cachedImageFile = null;
            _isLoading = true;
            _hasError = false;
          });
          _loadImage();
        }
      });

      // Show shimmer while reloading
      return const ImageShimmerPlaceholder();
    }

    return Image.file(
      _cachedImageFile!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        log('❌ [ImageWidget-${widget.image.id}] Image display error: $error', name: 'ImageGridItem');
        return Container(
          color: Colors.grey[300],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
              SizedBox(height: 4),
              Text(
                'Display error',
                style: TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
