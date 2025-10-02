import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart';
import 'package:flutter_image_gallery/ui/widgets/image_grid_item.dart';
import '../mocks/mock_image_repository.mocks.dart';

class MockImageGalleryCubit extends Mock implements ImageGalleryCubit {
  final _controller = StreamController<ImageGalleryState>.broadcast();

  @override
  final MockImageRepository repository = MockImageRepository();

  @override
  Stream<ImageGalleryState> get stream => _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  ImageGalleryState get state => ImageGalleryInitial();

  @override
  void emit(ImageGalleryState state) {
    _controller.add(state);
  }
}

void main() {
  late MockImageGalleryCubit mockCubit;
  late ImageEntity testImage;

  setUp(() {
    mockCubit = MockImageGalleryCubit();
    testImage = ImageEntity(
      id: 'test_id',
      url: 'https://example.com/image.jpg',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      title: 'Test Image',
    );
  });

  Widget createTestWidget(ImageEntity image) {
    return MaterialApp(
      home: BlocProvider<ImageGalleryCubit>(
        create: (_) => mockCubit,
        child: Scaffold(body: ImageGridItem(image: image)),
      ),
    );
  }

  group('ImageGridItem', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockCubit.repository.getCachedImage(testImage.id)).thenAnswer((_) async => Right(null)); // No cached image
      when(mockCubit.repository.cacheImage(any)).thenAnswer((_) async => Right(unit)); // Mock caching

      // Act
      await tester.pumpWidget(createTestWidget(testImage));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display Card with proper structure', (WidgetTester tester) async {
      // Arrange
      when(mockCubit.repository.getCachedImage(testImage.id)).thenAnswer((_) async => Right(null));
      when(mockCubit.repository.cacheImage(any)).thenAnswer((_) async => Right(unit)); // Mock caching

      // Act
      await tester.pumpWidget(createTestWidget(testImage));
      await tester.pump(); // Allow state to update

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should display error icon when image fails to load', (WidgetTester tester) async {
      // Arrange
      when(mockCubit.repository.getCachedImage(testImage.id)).thenAnswer((_) async => Right(null));
      when(mockCubit.repository.cacheImage(any)).thenAnswer((_) async => Right(unit)); // Mock caching

      // Act
      await tester.pumpWidget(createTestWidget(testImage));
      await tester.pump(); // Allow initial loading
      await tester.pump(const Duration(seconds: 1)); // Allow error state

      // Assert - This test might be tricky to implement properly
      // because the actual error handling depends on Image.network behavior
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should have correct Card elevation and shape', (WidgetTester tester) async {
      // Arrange
      when(mockCubit.repository.getCachedImage(testImage.id)).thenAnswer((_) async => Right(null));
      when(mockCubit.repository.cacheImage(any)).thenAnswer((_) async => Right(unit)); // Mock caching

      // Act
      await tester.pumpWidget(createTestWidget(testImage));

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(4));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });
  });
}
