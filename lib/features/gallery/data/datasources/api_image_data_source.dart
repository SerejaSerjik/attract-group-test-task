import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_gallery/core/error/failures.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/image_data_source.dart';
import 'package:flutter_image_gallery/features/gallery/domain/entities/image_entity.dart';
import 'package:flutter_image_gallery/features/gallery/data/dtos/image_dto.dart';
import 'package:flutter_image_gallery/features/gallery/data/mappers/image_mapper.dart';
import 'package:flutter_image_gallery/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@Singleton(as: ImageDataSource)
@Named('infinite_scroll')
class ApiImageDataSource implements ImageDataSource {
  static const String _baseUrl = Constants.apiBaseUrl;
  static const String _photosEndpoint = Constants.apiPhotosEndpoint;

  @override
  Future<void> init() async {
    // No initialization needed for API data source
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> fetchImages({int page = 1, int limit = 30}) async {
    try {
      log('🌐 [ApiDataSource] Fetching images from Picsum page $page, limit $limit', name: 'ApiDataSource');
      final response = await http.get(Uri.parse('$_baseUrl$_photosEndpoint?page=$page&limit=$limit'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final images = data.map((item) => ImageMapper.toEntity(ImageDto.fromJson(item))).toList();

        log(
          '✅ [ApiDataSource] Successfully fetched ${images.length} images from Picsum page $page',
          name: 'ApiDataSource',
        );
        return Right(images);
      } else {
        log('❌ [ApiDataSource] HTTP error: ${response.statusCode}', name: 'ApiDataSource');
        return Left(ServerFailure('HTTP ${response.statusCode}: ${response.reasonPhrase}'));
      }
    } on FormatException catch (e) {
      log('❌ [ApiDataSource] JSON parsing error: $e', name: 'ApiDataSource');
      return Left(ServerFailure('Invalid JSON response: $e'));
    } on http.ClientException catch (e) {
      log('❌ [ApiDataSource] Network error: $e', name: 'ApiDataSource');
      return Left(NetworkFailure('Network connection failed: $e'));
    } catch (e) {
      log('❌ [ApiDataSource] Unknown error: $e', name: 'ApiDataSource');
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> cacheImage(ImageEntity image) async {
    return Left(CacheFailure('ApiImageDataSource does not support caching images'));
  }

  @override
  Future<Either<Failure, ImageEntity?>> getCachedImage(String id) async {
    return Left(CacheFailure('ApiImageDataSource does not support retrieving cached images'));
  }

  @override
  Future<Either<Failure, bool>> isImageCached(String id) async {
    return Left(CacheFailure('ApiImageDataSource does not support checking if images are cached'));
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getCachedImages({int offset = 0, int limit = 30}) async {
    return Left(CacheFailure('ApiImageDataSource does not support getting cached images'));
  }

  @override
  Future<Either<Failure, int>> getCacheSize() async {
    return Left(CacheFailure('ApiImageDataSource does not support getting cache size'));
  }

  @override
  Future<Either<Failure, Unit>> clearCacheToLimit(int maxSizeBytes) async {
    return Left(CacheFailure('ApiImageDataSource does not support clearing cache'));
  }
}
