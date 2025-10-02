import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_images_usecase.dart';
import '../../../mocks/mock_image_repository.mocks.dart';

void main() {
  late GetImagesUseCase useCase;
  late MockImageRepository mockRepository;

  setUp(() {
    mockRepository = MockImageRepository();
    useCase = GetImagesUseCase(mockRepository);
  });

  group('GetImagesUseCase', () {
    final testImages = [
      ImageEntity(
        id: '1',
        url: 'https://example.com/1.jpg',
        thumbnailUrl: 'https://example.com/thumb/1.jpg',
        title: 'Test Image 1',
      ),
      ImageEntity(
        id: '2',
        url: 'https://example.com/2.jpg',
        thumbnailUrl: 'https://example.com/thumb/2.jpg',
        title: 'Test Image 2',
      ),
    ];

    test('should return images from repository', () async {
      // Arrange
      when(mockRepository.getImages(page: 1, limit: 30)).thenAnswer((_) async => Right(testImages));

      // Act
      final result = await useCase(page: 1, limit: 30);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (images) => expect(images, equals(testImages)),
      );
      verify(mockRepository.getImages(page: 1, limit: 30));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should use default parameters when not specified', () async {
      // Arrange
      when(mockRepository.getImages(page: 1, limit: 30)).thenAnswer((_) async => Right(testImages));

      // Act
      final result = await useCase();

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (images) => expect(images, equals(testImages)),
      );
      verify(mockRepository.getImages(page: 1, limit: 30)).called(1);
    });

    test('should pass custom parameters correctly', () async {
      // Arrange
      const customPage = 2;
      const customLimit = 50;
      when(mockRepository.getImages(page: customPage, limit: customLimit)).thenAnswer((_) async => Right(testImages));

      // Act
      final result = await useCase(page: customPage, limit: customLimit);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (images) => expect(images, equals(testImages)),
      );
      verify(mockRepository.getImages(page: customPage, limit: customLimit)).called(1);
    });

    test('should handle empty results', () async {
      // Arrange
      when(mockRepository.getImages(page: 1, limit: 30)).thenAnswer((_) async => Right(<ImageEntity>[]));

      // Act
      final result = await useCase();

      // Assert
      result.fold((failure) => fail('Expected success but got failure: $failure'), (images) {
        expect(images, isEmpty);
        expect(images, isA<List<ImageEntity>>());
      });
    });

    test('should handle repository failures', () async {
      // Arrange
      final failure = ServerFailure('Repository error');
      when(mockRepository.getImages(page: 1, limit: 30)).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase();

      // Assert
      result.fold(
        (failure) => expect(failure, equals(failure)),
        (images) => fail('Expected failure but got success: $images'),
      );
      verify(mockRepository.getImages(page: 1, limit: 30)).called(1);
    });
  });
}
