// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_image_gallery/features/gallery/data/datasources/api_image_data_source.dart'
    as _i512;
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_data_source.dart'
    as _i868;
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart'
    as _i849;
import 'package:flutter_image_gallery/features/gallery/data/datasources/image_data_source.dart'
    as _i455;
import 'package:flutter_image_gallery/features/gallery/data/repositories/image_repository_impl.dart'
    as _i878;
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart'
    as _i772;
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_images_usecase.dart'
    as _i855;
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_infinite_scroll_images_usecase.dart'
    as _i229;
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart'
    as _i787;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i849.CacheManagerService>(
        () => _i849.CacheManagerService());
    gh.singleton<_i455.ImageDataSource>(
      () => _i512.ApiImageDataSource(),
      instanceName: 'infinite_scroll',
    );
    gh.lazySingleton<_i455.ImageDataSource>(
      () => _i868.CacheDataSource(gh<_i849.CacheManagerService>()),
      instanceName: 'cache',
    );
    gh.lazySingleton<_i772.ImageRepository>(() => _i878.ImageRepositoryImpl(
          gh<_i455.ImageDataSource>(instanceName: 'infinite_scroll'),
          gh<_i455.ImageDataSource>(instanceName: 'cache'),
          gh<_i849.CacheManagerService>(),
        ));
    gh.lazySingleton<_i855.GetImagesUseCase>(
        () => _i855.GetImagesUseCase(gh<_i772.ImageRepository>()));
    gh.lazySingleton<_i229.GetInfiniteScrollImagesUseCase>(() =>
        _i229.GetInfiniteScrollImagesUseCase(gh<_i772.ImageRepository>()));
    gh.lazySingleton<_i787.ImageGalleryCubit>(() => _i787.ImageGalleryCubit(
          gh<_i229.GetInfiniteScrollImagesUseCase>(),
          gh<_i772.ImageRepository>(),
        ));
    return this;
  }
}
