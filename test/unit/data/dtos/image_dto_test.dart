import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_gallery/features/gallery/data/dtos/image_dto.dart';

void main() {
  group('ImageDto', () {
    test('should create ImageDto with required parameters', () {
      // Arrange
      const id = 'test_id';
      const url = 'https://example.com/image.jpg';
      const thumbnailUrl = 'https://example.com/thumb.jpg';
      const title = 'Test Image';

      // Act
      final dto = ImageDto(id: id, url: url, thumbnailUrl: thumbnailUrl, title: title);

      // Assert
      expect(dto.id, equals(id));
      expect(dto.url, equals(url));
      expect(dto.thumbnailUrl, equals(thumbnailUrl));
      expect(dto.title, equals(title));
      expect(dto.cachedPath, isNull);
      expect(dto.cachedAt, isNull);
      expect(dto.fileSize, isNull);
    });

    test('should create ImageDto with all parameters', () {
      // Arrange
      const id = 'test_id';
      const url = 'https://example.com/image.jpg';
      const thumbnailUrl = 'https://example.com/thumb.jpg';
      const title = 'Test Image';
      const cachedPath = '/cache/images/test.jpg';
      final cachedAt = DateTime(2024, 1, 1);
      const fileSize = 1024000;

      // Act
      final dto = ImageDto(
        id: id,
        url: url,
        thumbnailUrl: thumbnailUrl,
        title: title,
        cachedPath: cachedPath,
        cachedAt: cachedAt,
        fileSize: fileSize,
      );

      // Assert
      expect(dto.id, equals(id));
      expect(dto.url, equals(url));
      expect(dto.thumbnailUrl, equals(thumbnailUrl));
      expect(dto.title, equals(title));
      expect(dto.cachedPath, equals(cachedPath));
      expect(dto.cachedAt, equals(cachedAt));
      expect(dto.fileSize, equals(fileSize));
    });

    group('fromJson', () {
      test('should parse JSON correctly', () {
        // Arrange
        final json = {
          'id': '123',
          'download_url': 'https://picsum.photos/200/300?image=123',
          'author': 'Test Author',
          'width': 200,
          'height': 300,
          'url': 'https://picsum.photos/id/123/info',
        };

        // Act
        final dto = ImageDto.fromJson(json);

        // Assert
        expect(dto.id, equals('123'));
        expect(dto.url, equals('https://picsum.photos/200/300?image=123'));
        expect(dto.thumbnailUrl, equals('https://picsum.photos/200/300?image=123'));
        expect(dto.title, equals('Image 123'));
        expect(dto.cachedPath, isNull);
        expect(dto.cachedAt, isNull);
        expect(dto.fileSize, isNull);
      });

      test('should handle missing optional fields', () {
        // Arrange
        final minimalJson = {'id': '456', 'download_url': 'https://example.com/image.jpg'};

        // Act
        final dto = ImageDto.fromJson(minimalJson);

        // Assert
        expect(dto.id, equals('456'));
        expect(dto.url, equals('https://example.com/image.jpg'));
        expect(dto.thumbnailUrl, equals('https://example.com/image.jpg'));
        expect(dto.title, equals('Image 456'));
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final cachedAt = DateTime(2024, 1, 1, 12, 30, 45);
        final dto = ImageDto(
          id: '789',
          url: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          title: 'Test DTO',
          cachedPath: '/cache/789.jpg',
          cachedAt: cachedAt,
          fileSize: 2048000,
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['id'], equals('789'));
        expect(json['url'], equals('https://example.com/image.jpg'));
        expect(json['thumbnailUrl'], equals('https://example.com/thumb.jpg'));
        expect(json['title'], equals('Test DTO'));
        expect(json['cachedPath'], equals('/cache/789.jpg'));
        expect(json['cachedAt'], equals(cachedAt.toIso8601String()));
        expect(json['fileSize'], equals(2048000));
      });

      test('should handle null values in JSON', () {
        // Arrange
        final dto = ImageDto(
          id: '999',
          url: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          title: 'Null Test',
          // Optional fields are null
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['cachedPath'], isNull);
        expect(json['cachedAt'], isNull);
        expect(json['fileSize'], isNull);
      });
    });
  });
}
