import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/data/repositories/image_repository_impl.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_images_usecase.dart';
import '../mocks/mock_image_data_source.mocks.dart';

class MockCacheManagerService extends Mock implements CacheManagerService {}

void main() {
  late ImageRepositoryImpl repository;
  late GetImagesUseCase useCase;
  late MockImageDataSource mockInfiniteScrollDataSource;
  late MockImageDataSource mockCacheDataSource;
  late MockCacheManagerService mockCacheManagerService;

  setUp(() {
    mockInfiniteScrollDataSource = MockImageDataSource();
    mockCacheDataSource = MockImageDataSource();
    mockCacheManagerService = MockCacheManagerService();
    repository = ImageRepositoryImpl(mockInfiniteScrollDataSource, mockCacheDataSource, mockCacheManagerService);
    useCase = GetImagesUseCase(repository);
  });

  group('Gallery Integration Tests', () {
    final testImages = List.generate(
      30,
      (index) => ImageEntity(
        id: index.toString(),
        url: 'https://example.com/$index.jpg',
        thumbnailUrl: 'https://example.com/thumb/$index.jpg',
        title: 'Test Image $index',
      ),
    );

    test('should load images from cache when available', () async {
      // Arrange
      when(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).thenAnswer((_) async => Right(testImages));

      // Act
      final result = await useCase(page: 1, limit: 30);

      // Assert
      result.fold((failure) => fail('Expected success but got failure: $failure'), (images) {
        expect(images, equals(testImages));
        expect(images.length, equals(30));
      });
      verify(mockCacheDataSource.getCachedImages(offset: 0, limit: 30));
      verifyNever(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30));
    });

    test('should fetch from API and cache when cache is empty', () async {
      // Arrange
      when(
        mockCacheDataSource.getCachedImages(offset: 0, limit: 30),
      ).thenAnswer((_) async => Right([])); // Cache is empty
      when(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30)).thenAnswer((_) async => Right(testImages));
      when(mockCacheDataSource.cacheImage(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase(page: 1, limit: 30);

      // Assert
      result.fold((failure) => fail('Expected success but got failure: $failure'), (images) {
        expect(images, equals(testImages));
        expect(images.length, equals(30));
      });
      verify(mockCacheDataSource.getCachedImages(offset: 0, limit: 30));
      verify(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30));
      verify(mockCacheDataSource.cacheImage(any)).called(30); // All images cached
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).thenAnswer((_) async => Right([])); // Cache empty
      when(
        mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30),
      ).thenAnswer((_) async => Left(ServerFailure('Network error')));

      // Act
      final result = await useCase(page: 1, limit: 30);

      // Assert
      result.fold((failure) {
        expect(failure, isA<Failure>());
      }, (images) => fail('Expected failure but got success: $images'));
      verify(mockCacheDataSource.getCachedImages(offset: 0, limit: 30));
      verify(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30));
    });

    test('should cache images after fetching from API', () async {
      // Arrange
      final apiImages = testImages.take(15).toList(); // API returns 15 images

      when(mockCacheDataSource.getCachedImages(offset: 0, limit: 30)).thenAnswer((_) async => Right([])); // Cache empty
      when(mockInfiniteScrollDataSource.fetchImages(page: 1, limit: 30)).thenAnswer((_) async => Right(apiImages));
      when(mockCacheDataSource.cacheImage(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase(page: 1, limit: 30);

      // Assert
      result.fold((failure) => fail('Expected success but got failure: $failure'), (images) {
        expect(images, equals(apiImages));
      });
      verify(mockCacheDataSource.cacheImage(any)).called(apiImages.length);
    });
  });
}
