# Flutter Image Gallery - Injectable Dependency Injection Implementation

## Overview

This document describes the implementation of proper dependency injection using the Injectable package with GetIt for the Flutter Image Gallery application.

## Dependency Injection Setup

### Packages Used

```yaml
dependencies:
  injectable: ^2.1.2
  get_it: ^7.2.0

dev_dependencies:
  injectable_generator: ^2.1.2
  build_runner: ^2.4.11
```

### Service Locator

The service locator pattern is implemented using GetIt with generated code from Injectable:

```dart
// service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'service_locator.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureDependencies() => getIt.init();
```

### Generated Code

The build runner generates `service_locator.config.dart` with all dependency registrations:

```dart
// Generated code excerpt
gh.singleton<_i491.ImageDataSource>(
  () => _i814.ApiImageDataSource(),
  instanceName: 'api',
);
gh.singleton<_i491.ImageDataSource>(
  () => _i540.HiveImageDataSource(),
  instanceName: 'cache',
);
gh.factory<_i772.ImageRepository>(() => _i878.ImageRepositoryImpl(
      gh<_i491.ImageDataSource>(instanceName: 'api'),
      gh<_i491.ImageDataSource>(instanceName: 'cache'),
    ));
```

## Injectable Annotations

### Singleton Registration

Data sources are registered as singletons with named instances:

```dart
@Singleton(as: ImageDataSource)
@Named('api')
class ApiImageDataSource implements ImageDataSource {
  // Implementation
}

@Singleton(as: ImageDataSource)
@Named('cache')
class HiveImageDataSource implements ImageDataSource {
  // Implementation
}
```

### Factory Registration

Other components are registered as factories:

```dart
@Injectable(as: ImageRepository)
class ImageRepositoryImpl implements ImageRepository {
  ImageRepositoryImpl(@Named('api') this._apiDataSource, @Named('cache') this._cacheDataSource);
  // Implementation
}

@injectable
class GetImagesUseCase {
  // Implementation
}

@injectable
class ImageGalleryProvider with ChangeNotifier {
  // Implementation
}
```

## Dependency Resolution

### Component Registration

1. **ApiImageDataSource**: Registered as singleton with name 'api'
2. **HiveImageDataSource**: Registered as singleton with name 'cache'
3. **ImageRepositoryImpl**: Registered as factory with ImageRepository interface
4. **GetImagesUseCase**: Registered as factory
5. **ImageGalleryProvider**: Registered as factory

### Injection Points

Dependencies are injected through constructor injection:

```dart
class ImageRepositoryImpl implements ImageRepository {
  final ImageDataSource _apiDataSource;
  final ImageDataSource _cacheDataSource;

  ImageRepositoryImpl(
    @Named('api') this._apiDataSource, 
    @Named('cache') this._cacheDataSource
  );
  // Implementation
}
```

## Initialization Process

### Application Startup

```dart
void main() {
  configureDependencies(); // Initialize GetIt with generated dependencies
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  // Initialize cache data source
  final cacheDataSource = getIt<HiveImageDataSource>();
  await cacheDataSource.init();

  // Initialize repository cache
  final repository = getIt<ImageRepository>();
  await repository.initializeCache();
}
```

## Benefits of Injectable Implementation

### 1. Compile-Time Safety

- Generated code ensures all dependencies can be resolved
- Type-safe dependency injection
- Early detection of missing dependencies

### 2. Reduced Boilerplate

- Automatic registration of dependencies
- No manual GetIt registration code
- Clean, readable component definitions

### 3. Flexibility

- Easy to swap implementations
- Support for named instances
- Environment-specific configurations

### 4. Performance

- Lazy initialization by default
- Singleton pattern enforcement
- Efficient dependency resolution

## Generated Files

### service_locator.config.dart

Contains all dependency registration logic:

- Singleton registrations
- Factory registrations
- Named instance handling
- Constructor parameter injection

### Build Process

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Generates dependency injection code based on annotations.

## Component Lifecycle

### Registration Order

1. **Singletons**: Created during GetIt initialization
2. **Factories**: Created on first request
3. **Named Instances**: Resolved by name and type

### Initialization Sequence

1. `configureDependencies()` - Register all dependencies
2. `HiveImageDataSource.init()` - Initialize Hive database
3. `ImageRepository.initializeCache()` - Check and clean cache

## Testing Support

### Mocking Dependencies

Easy to replace real dependencies with mocks for testing:

```dart
// In tests
getIt.registerSingleton<ImageDataSource>(
  MockApiDataSource(), 
  instanceName: 'api'
);
```

### Integration Testing

Real dependencies can be used for integration tests:

```dart
// In integration tests
final repository = getIt<ImageRepository>();
// Test with real data sources
```

## Error Handling

### Missing Dependencies

Compile-time errors for unresolved dependencies:

```
Error: Could not find a register for type ...
```

### Circular Dependencies

Build runner detects and reports circular dependencies.

## Best Practices

### 1. Interface-Based Design

All dependencies should depend on abstractions:

```dart
@Singleton(as: ImageDataSource)
class ApiImageDataSource implements ImageDataSource
```

### 2. Constructor Injection

Use constructor injection for all dependencies:

```dart
ImageRepositoryImpl(@Named('api') this._apiDataSource, @Named('cache') this._cacheDataSource);
```

### 3. Named Instances

Use named instances for multiple implementations of the same interface:

```dart
@Named('api')
@Named('cache')
```

## Conclusion

The Injectable package with GetIt provides a robust, type-safe dependency injection solution for the Flutter Image Gallery application. The implementation follows best practices for clean architecture while providing the flexibility and performance benefits of a proper DI framework.

All components are properly registered and can be resolved at runtime, ensuring a maintainable and testable codebase.