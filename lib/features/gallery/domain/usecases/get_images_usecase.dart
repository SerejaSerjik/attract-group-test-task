import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class GetImagesUseCase {
  final ImageRepository repository;

  GetImagesUseCase(this.repository);

  Future<Either<Failure, List<ImageEntity>>> call({int page = 1, int limit = 30}) async {
    return await repository.getImages(page: page, limit: limit);
  }
}
