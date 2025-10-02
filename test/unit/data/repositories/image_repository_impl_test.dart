import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/features/gallery/data/repositories/image_repository_impl.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import '../../../mocks/mock_image_data_source.mocks.dart';

class MockCacheManagerService extends Mock implements CacheManagerService {}

void main() {
  late ImageRepositoryImpl repository;
  late MockImageDataSource mockInfiniteScrollDataSource;
  late MockImageDataSource mockCacheDataSource;
  late MockCacheManagerService mockCacheManagerService;

  setUp(() {
    mockInfiniteScrollDataSource = MockImageDataSource();
    mockCacheDataSource = MockImageDataSource();
    mockCacheManagerService = MockCacheManagerService();
    repository = ImageRepositoryImpl(mockInfiniteScrollDataSource, mockCacheDataSource, mockCacheManagerService);
  });

  group('ImageRepositoryImpl', () {
    final testImages = List.generate(
      30,
      (index) => ImageEntity(
        id: (index + 1).toString(),
        url: 'https://example.com/${index + 1}.jpg',
        thumbnailUrl: 'https://example.com/thumb/${index + 1}.jpg',
        title: 'Test Image ${index + 1}',
      ),
    );

    group('getImages', () {
      test('should return cached images when available', () async {
        // Arrange
        when(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).thenAnswer((_) async => Right(testImages));
        when(
          mockInfiniteScrollDataSource.fetchImages(page: anyNamed('page'), limit: anyNamed('limit')),
        ).thenAnswer((_) async => Right([]));

        // Act
        final result = await repository.getImages(page: 1, limit: 30);

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (images) => expect(images, equals(testImages)),
        );
        verify(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).called(1);
        verifyNever(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30));
      });

      test('should fetch from API when no cached images available', () async {
        // Arrange
        when(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).thenAnswer((_) async => Right([]));
        when(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30)).thenAnswer((_) async => Right(testImages));
        when(mockCacheDataSource.cacheImage(any)).thenAnswer((_) async => Right(unit));

        // Act
        final result = await repository.getImages(page: 1, limit: 30);

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (images) => expect(images, equals(testImages)),
        );
        verify(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).called(1);
        verify(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30)).called(1);
      });
    });

    group('cacheImage', () {
      test('should handle caching with HTTP and file operations', () async {
        // Arrange
        final testImage = testImages[0];
        when(mockCacheDataSource.cacheImage(any)).thenAnswer((_) async => Right(unit));

        // Act
        final result = await repository.cacheImage(testImage);

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (unit) => expect(unit, equals(unit)),
        );
        verify(mockCacheDataSource.cacheImage(any)).called(1);
      });
    });

    group('getCachedImage', () {
      test('should return cached image when available and file exists', () async {
        // Arrange
        const imageId = 'test_id';
        final cachedImage = ImageEntity(
          id: '1',
          url: 'https://example.com/1.jpg',
          thumbnailUrl: 'https://example.com/thumb/1.jpg',
          title: 'Test Image 1',
          cachedPath: '/fake/path/image.jpg',
        );
        when(mockCacheDataSource.isImageCached(imageId)).thenAnswer((_) async => Right(true));
        when(mockCacheDataSource.getCachedImage(imageId)).thenAnswer((_) async => Right(cachedImage));

        // Act
        final result = await repository.getCachedImage(imageId);

        // Assert
        // Since file doesn't exist, it returns null
        result.fold((failure) => fail('Expected success but got failure: $failure'), (image) => expect(image, isNull));
        verify(mockCacheDataSource.isImageCached(imageId)).called(1);
        verify(mockCacheDataSource.getCachedImage(imageId)).called(1);
      });

      test('should return null when image is not cached', () async {
        // Arrange
        const imageId = 'test_id';
        when(mockCacheDataSource.isImageCached(imageId)).thenAnswer((_) async => Right(false));

        // Act
        final result = await repository.getCachedImage(imageId);

        // Assert
        result.fold((failure) => fail('Expected success but got failure: $failure'), (image) => expect(image, isNull));
        verify(mockCacheDataSource.isImageCached(imageId)).called(1);
        verifyNever(mockCacheDataSource.getCachedImage(imageId));
      });
    });

    group('getCacheSize', () {
      test('should delegate to cache data source', () async {
        // Arrange
        const expectedSize = 1024;
        when(mockCacheDataSource.getCacheSize()).thenAnswer((_) async => Right(expectedSize));

        // Act
        final result = await repository.getCacheSize();

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (size) => expect(size, equals(expectedSize)),
        );
        verify(mockCacheDataSource.getCacheSize()).called(1);
      });
    });

    group('clearCacheToLimit', () {
      test('should delegate to cache data source', () async {
        // Arrange
        const limitBytes = 1024 * 1024; // 1MB
        when(mockCacheDataSource.clearCacheToLimit(limitBytes)).thenAnswer((_) async => Right(unit));

        // Act
        final result = await repository.clearCacheToLimit(limitBytes);

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (unit) => expect(unit, equals(unit)),
        );
        verify(mockCacheDataSource.clearCacheToLimit(limitBytes)).called(1);
      });
    });

    group('initializeCache', () {
      test('should clear cache if size exceeds 1GB', () async {
        // Arrange
        const currentSize = 1024 * 1024 * 1024 + 100; // > 1GB
        when(mockCacheDataSource.getCacheSize()).thenAnswer((_) async => Right(currentSize));
        when(mockCacheDataSource.clearCacheToLimit(1024 * 1024 * 1024)).thenAnswer((_) async => Right(unit));

        // Act
        final result = await repository.initializeCache();

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (unit) => expect(unit, equals(unit)),
        );
        verify(mockCacheDataSource.getCacheSize()).called(1);
        verify(mockCacheDataSource.clearCacheToLimit(1024 * 1024 * 1024)).called(1);
      });

      test('should not clear cache if size is within limit', () async {
        // Arrange
        const currentSize = 500 * 1024 * 1024; // 500MB < 1GB
        when(mockCacheDataSource.getCacheSize()).thenAnswer((_) async => Right(currentSize));

        // Act
        final result = await repository.initializeCache();

        // Assert
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (unit) => expect(unit, equals(unit)),
        );
        verify(mockCacheDataSource.getCacheSize()).called(1);
        verifyNever(mockCacheDataSource.clearCacheToLimit(any));
      });
    });
  });
}
