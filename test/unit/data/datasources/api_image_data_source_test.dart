import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/api_image_data_source.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:dartz/dartz.dart';

void main() {
  late ApiImageDataSource dataSource;

  setUp(() {
    dataSource = ApiImageDataSource();
  });

  group('ApiImageDataSource', () {
    final testImage = ImageEntity(
      id: 'test',
      url: 'https://example.com/test.jpg',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      title: 'Test Image',
    );

    test('should return CacheFailure for unsupported cache operations', () async {
      final cacheResult = await dataSource.cacheImage(testImage);
      expect(cacheResult, isA<Left<Failure, Unit>>());
      cacheResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (unit) => fail('Expected failure but got success'),
      );

      final getCachedResult = await dataSource.getCachedImage('id');
      expect(getCachedResult, isA<Left<Failure, ImageEntity?>>());
      getCachedResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (entity) => fail('Expected failure but got success'),
      );

      final isCachedResult = await dataSource.isImageCached('id');
      expect(isCachedResult, isA<Left<Failure, bool>>());
      isCachedResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (isCached) => fail('Expected failure but got success'),
      );

      final getCachedImagesResult = await dataSource.getCachedImages();
      expect(getCachedImagesResult, isA<Left<Failure, List<ImageEntity>>>());
      getCachedImagesResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (images) => fail('Expected failure but got success'),
      );

      final getCacheSizeResult = await dataSource.getCacheSize();
      expect(getCacheSizeResult, isA<Left<Failure, int>>());
      getCacheSizeResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (size) => fail('Expected failure but got success'),
      );

      final clearCacheResult = await dataSource.clearCacheToLimit(1000);
      expect(clearCacheResult, isA<Left<Failure, Unit>>());
      clearCacheResult.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (unit) => fail('Expected failure but got success'),
      );
    });

    // Integration test would require mocking http client properly
    // test('should fetch images from API', () async {
    //   // Mock HTTP response
    //   when(mockHttpClient.get(any))
    //       .thenAnswer((_) async => http.Response('[]', 200));
    //
    //   final images = await dataSource.fetchImages(page: 1, limit: 10);
    //   expect(images, isA<List<ImageEntity>>());
    // });
  });
}
