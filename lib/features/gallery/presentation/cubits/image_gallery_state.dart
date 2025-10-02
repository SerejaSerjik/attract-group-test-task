part of 'image_gallery_cubit.dart';

// Gallery always operates in infinite scroll mode

abstract class ImageGalleryState extends Equatable {
  const ImageGalleryState();

  @override
  List<Object> get props => [];
}

class ImageGalleryInitial extends ImageGalleryState {}

class ImageGalleryLoading extends ImageGalleryState {}

class ImageGalleryLoadingMore extends ImageGalleryState {
  final List<ImageEntity> currentImages;
  final int cacheSizeBytes;

  const ImageGalleryLoadingMore({required this.currentImages, required this.cacheSizeBytes});

  @override
  List<Object> get props => [currentImages, cacheSizeBytes];
}

class ImageGalleryLoaded extends ImageGalleryState {
  final List<ImageEntity> images;
  final bool hasMoreData;
  final int cacheSizeBytes;

  const ImageGalleryLoaded({required this.images, required this.hasMoreData, required this.cacheSizeBytes});

  @override
  List<Object> get props => [images, hasMoreData, cacheSizeBytes];
}

class ImageGalleryError extends ImageGalleryState {
  final String message;

  const ImageGalleryError({required this.message});

  @override
  List<Object> get props => [message];
}

class ImageGalleryDatabasePopulated extends ImageGalleryState {}

class ImageGalleryCacheSizeUpdated extends ImageGalleryState {
  final int cacheSizeBytes;
  final List<dynamic> cacheHistory;

  const ImageGalleryCacheSizeUpdated({required this.cacheSizeBytes, required this.cacheHistory});

  @override
  List<Object> get props => [cacheSizeBytes, cacheHistory];
}
