import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_image_gallery/core/di/service_locator.dart';
import 'package:flutter_image_gallery/features/gallery/presentation/cubits/image_gallery_cubit.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/image_data_source.dart';
import 'package:flutter_image_gallery/features/gallery/data/datasources/cache_manager_service.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/get_infinite_scroll_images_usecase.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/populate_realm_database_usecase.dart';
import 'package:flutter_image_gallery/features/gallery/domain/usecases/fast_fill_cache_usecase.dart';
import 'package:flutter_image_gallery/features/gallery/domain/repositories/image_repository.dart';
import 'package:flutter_image_gallery/ui/screens/home_screen.dart';
import 'package:flutter_image_gallery/ui/themes/app_theme.dart';
import 'package:flutter_image_gallery/l10n/app_localizations.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: Scaffold(body: Center(child: Text('Error initializing app: ${snapshot.error}'))),
          );
        } else {
          return MaterialApp(
            title: 'Flutter Image Gallery',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
            ],
            home: BlocProvider(
              create: (context) {
                final cubit = getIt<ImageGalleryCubit>();
                // If cubit is closed (happens during hot reload or tab switches), get a fresh one
                if (cubit.isClosed) {
                  log('🔄 [Main] Cubit was closed, creating fresh instance', name: 'Main');
                  // Unregister and re-register to get a fresh instance
                  getIt.unregister<ImageGalleryCubit>();
                  getIt.registerLazySingleton<ImageGalleryCubit>(
                    () => ImageGalleryCubit(
                      getIt<GetInfiniteScrollImagesUseCase>(),
                      getIt<PopulateRealmDatabaseUseCase>(),
                      getIt<FastFillCacheUseCase>(),
                      getIt<ImageRepository>(),
                    ),
                  );
                  return getIt<ImageGalleryCubit>();
                }
                return cubit;
              },
              child: const HomeScreen(),
            ),
          );
        }
      },
    );
  }

  Future<void> _initializeApp() async {
    // Initialize data sources
    final infiniteScrollDataSource = getIt<ImageDataSource>(instanceName: 'infinite_scroll');
    final cacheDataSource = getIt<ImageDataSource>(instanceName: 'cache');

    await infiniteScrollDataSource.init();
    await cacheDataSource.init(); // This initializes dummy cache (no-op)

    // Initialize professional cache manager
    final cacheManagerService = getIt<CacheManagerService>();
    await cacheManagerService.init(); // This initializes flutter_cache_manager

    // Initialize repository cache
    final repository = getIt<ImageRepository>();
    await repository.initializeCache();
  }
}
