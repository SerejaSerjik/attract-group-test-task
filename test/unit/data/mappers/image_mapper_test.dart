import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/data/dtos/image_dto.dart';
import 'package:flutter_image_gallery/features/gallery/data/mappers/image_mapper.dart';

void main() {
  group('ImageMapper', () {
    final testDto = ImageDto(
      id: '123',
      url: 'https://picsum.photos/200/300?image=123',
      thumbnailUrl: 'https://picsum.photos/200/300?image=123',
      title: 'Test Image',
      cachedPath: '/cache/images/123.jpg',
      cachedAt: DateTime(2024, 1, 1, 12, 0, 0),
      fileSize: 1024000, // 1MB
    );

    final testEntity = ImageEntity(
      id: '123',
      url: 'https://picsum.photos/200/300?image=123',
      thumbnailUrl: 'https://picsum.photos/200/300?image=123',
      title: 'Test Image',
      cachedPath: '/cache/images/123.jpg',
      cachedAt: DateTime(2024, 1, 1, 12, 0, 0),
      fileSize: 1024000,
    );

    group('toEntity', () {
      test('should convert DTO to Entity correctly', () {
        // Act
        final result = ImageMapper.toEntity(testDto);

        // Assert
        expect(result.id, equals(testDto.id));
        expect(result.url, equals(testDto.url));
        expect(result.thumbnailUrl, equals(testDto.thumbnailUrl));
        expect(result.title, equals(testDto.title));
        expect(result.cachedPath, equals(testDto.cachedPath));
        expect(result.cachedAt, equals(testDto.cachedAt));
        expect(result.fileSize, equals(testDto.fileSize));
      });

      test('should handle null values in DTO', () {
        // Arrange
        final dtoWithNulls = ImageDto(
          id: '456',
          url: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          title: 'Null Test Image',
          // All optional fields are null
        );

        // Act
        final result = ImageMapper.toEntity(dtoWithNulls);

        // Assert
        expect(result.id, equals('456'));
        expect(result.cachedPath, isNull);
        expect(result.cachedAt, isNull);
        expect(result.fileSize, isNull);
      });
    });

    group('toDto', () {
      test('should convert Entity to DTO correctly', () {
        // Act
        final result = ImageMapper.toDto(testEntity);

        // Assert
        expect(result.id, equals(testEntity.id));
        expect(result.url, equals(testEntity.url));
        expect(result.thumbnailUrl, equals(testEntity.thumbnailUrl));
        expect(result.title, equals(testEntity.title));
        expect(result.cachedPath, equals(testEntity.cachedPath));
        expect(result.cachedAt, equals(testEntity.cachedAt));
        expect(result.fileSize, equals(testEntity.fileSize));
      });

      test('should handle null values in Entity', () {
        // Arrange
        final entityWithNulls = ImageEntity(
          id: '789',
          url: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          title: 'Null Test Entity',
          // All optional fields are null
        );

        // Act
        final result = ImageMapper.toDto(entityWithNulls);

        // Assert
        expect(result.id, equals('789'));
        expect(result.cachedPath, isNull);
        expect(result.cachedAt, isNull);
        expect(result.fileSize, isNull);
      });
    });

    group('round trip conversion', () {
      test('should maintain data integrity through DTO ↔ Entity conversion', () {
        // Act
        final dto = ImageMapper.toDto(testEntity);
        final entity = ImageMapper.toEntity(dto);

        // Assert
        expect(entity.id, equals(testEntity.id));
        expect(entity.url, equals(testEntity.url));
        expect(entity.thumbnailUrl, equals(testEntity.thumbnailUrl));
        expect(entity.title, equals(testEntity.title));
        expect(entity.cachedPath, equals(testEntity.cachedPath));
        expect(entity.cachedAt, equals(testEntity.cachedAt));
        expect(entity.fileSize, equals(testEntity.fileSize));
      });
    });
  });
}
