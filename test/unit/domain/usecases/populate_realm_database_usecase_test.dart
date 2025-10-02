import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/populate_realm_database_usecase.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import '../../../mocks/mock_image_repository.mocks.dart';

void main() {
  late PopulateRealmDatabaseUseCase useCase;
  late MockImageRepository mockRepository;

  setUp(() {
    mockRepository = MockImageRepository();
    useCase = PopulateRealmDatabaseUseCase(mockRepository);
  });

  group('PopulateRealmDatabaseUseCase', () {
    test('should call repository methods with correct parameters', () async {
      // Arrange
      const testImageCount = 50;
      const targetCacheSize = 900 * 1024 * 1024; // 900MB

      // Mock cache size checks - first call returns 0, subsequent calls return target size
      var callCount = 0;
      when(mockRepository.getCacheSize()).thenAnswer((_) async {
        callCount++;
        return Right(callCount == 1 ? 0 : targetCacheSize);
      });

      // Mock getting images from repository (return some images to trigger caching)
      final testImages = List.generate(
        30,
        (index) => ImageEntity(id: '$index', url: 'url$index', thumbnailUrl: 'thumb$index', title: 'Image $index'),
      );
      when(mockRepository.getImages(page: anyNamed('page'), limit: 30)).thenAnswer((_) async => Right(testImages));

      // Mock cacheImage to do nothing
      when(mockRepository.cacheImage(any)).thenAnswer((_) async => Right(unit));

      // Mock clearCacheToLimit
      when(mockRepository.clearCacheToLimit(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase(imageCount: testImageCount);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (unit) => expect(unit, equals(unit)),
      );
      verify(mockRepository.getCacheSize()).called(greaterThan(1));
      verify(mockRepository.getImages(page: anyNamed('page'), limit: 30)).called(greaterThan(0));
      verify(mockRepository.clearCacheToLimit(1024 * 1024 * 1024)).called(1);
    });

    test('should handle repository failures gracefully', () async {
      // Arrange
      final failure = ServerFailure('Repository error');
      when(mockRepository.getCacheSize()).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(imageCount: 10);

      // Assert
      result.fold((failure) => expect(failure, isA<Failure>()), (unit) => fail('Expected failure but got success'));
    });

    test('should use default image count when not specified', () async {
      // Arrange - cache is already at target size, so no images should be fetched
      when(mockRepository.getCacheSize()).thenAnswer((_) async => Right(900 * 1024 * 1024));
      when(mockRepository.clearCacheToLimit(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase();

      // Assert - getImages should not be called since cache is already at target size
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (unit) => expect(unit, equals(unit)),
      );
      verifyNever(mockRepository.getImages(page: anyNamed('page'), limit: 30));
      verify(mockRepository.getCacheSize()).called(2); // Initial check + final check
      verify(mockRepository.clearCacheToLimit(1024 * 1024 * 1024)).called(1);
    });

    test('should stop when target cache size is reached', () async {
      // Arrange
      const smallImageCount = 5;
      var callCount = 0;
      when(mockRepository.getCacheSize()).thenAnswer((_) async {
        callCount++;
        // First call returns 0, subsequent calls return target size
        return Right(callCount == 1 ? 0 : 900 * 1024 * 1024);
      });
      when(mockRepository.getImages(page: anyNamed('page'), limit: 30)).thenAnswer((_) async => Right(<ImageEntity>[]));
      when(mockRepository.clearCacheToLimit(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase(imageCount: smallImageCount);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (unit) => expect(unit, equals(unit)),
      );
      verify(mockRepository.clearCacheToLimit(any)).called(1);
    });
  });
}
