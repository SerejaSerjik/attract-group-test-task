# Flutter Image Gallery - Clean Architecture with Singletons

## Overview

This document describes the clean architecture implementation of the Flutter Image Gallery application with proper singleton patterns for all services and components.

## Architecture Layers

### 1. Domain Layer

The domain layer contains the core business logic and is independent of any framework or external dependencies.

#### Entities

- **ImageEntity**: Immutable data class representing an image with Equatable for proper equality comparison
- Implemented as a singleton through the factory pattern

#### Repositories

- **ImageRepository**: Abstract interface defining the contract for image data operations

#### Use Cases

- **GetImagesUseCase**: Encapsulates the business logic for fetching images
- Implemented as a singleton

### 2. Data Layer

The data layer implements the repository interface and handles data operations.

#### Data Sources

- **ImageDataSource**: Abstract interface for data operations
- **ApiImageDataSource**: Concrete implementation for fetching images from the API (singleton)
- **HiveImageDataSource**: Concrete implementation for caching images with Hive (singleton)

#### Repository Implementation

- **ImageRepositoryImpl**: Implements the ImageRepository interface using data sources

#### Mappers

- **ImageMapper**: Utility class for converting between entities and models (if needed)

### 3. Presentation Layer

The presentation layer handles UI and user interaction.

#### Providers

- **ImageGalleryProvider**: State management for the image gallery (singleton)

## Singleton Implementation Patterns

### Factory Pattern for Singletons

All major components implement the singleton pattern using Dart's factory constructor:

```dart
class ApiImageDataSource implements ImageDataSource {
  static final ApiImageDataSource _instance = ApiImageDataSource._internal();
  factory ApiImageDataSource() => _instance;
  ApiImageDataSource._internal();
  
  // Implementation details...
}
```

### Lazy Initialization in Injection Container

The injection container implements lazy initialization to ensure singletons are only created when needed:

```dart
class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  // Lazy initialization with getter
  ApiImageDataSource get apiDataSource => ApiImageDataSource();
  
  ImageRepository get imageRepository {
    _imageRepository ??= ImageRepositoryImpl(apiDataSource, cacheDataSource);
    return _imageRepository!;
  }
}
```

## Dependency Injection

### Service Locator Pattern

The application uses a service locator pattern through the InjectionContainer:

1. **Singleton Access**: All services are accessed through singleton instances
2. **Lazy Initialization**: Services are only instantiated when first accessed
3. **Async Initialization**: Services requiring async setup are initialized through the `init()` method

### Initialization Flow

```dart
Future<InjectionContainer> _initializeApp() async {
  final container = InjectionContainer();
  await container.init(); // Initialize async dependencies
  return container;
}
```

## Benefits of Singleton Architecture

### 1. Memory Efficiency

- Single instances reduce memory consumption
- Shared state across the application
- No duplicate initialization overhead

### 2. Consistent State

- Guaranteed single source of truth
- Consistent data across different parts of the application
- Proper cache management

### 3. Performance

- Reduced object creation overhead
- Efficient resource utilization
- Faster access to initialized services

### 4. Testability

- Easy to mock singleton dependencies
- Predictable behavior in tests
- Isolated unit testing

## Component Lifecycle

### 1. Application Startup

1. InjectionContainer is created as a singleton
2. Lazy initialization of services through getters
3. Async initialization of data sources through `init()` method

### 2. Service Initialization

1. ApiImageDataSource - Immediate availability (no async init required)
2. HiveImageDataSource - Requires async initialization for Hive setup
3. ImageRepositoryImpl - Created with data source dependencies
4. GetImagesUseCase - Created with repository dependency
5. ImageGalleryProvider - Created with use case dependency

### 3. Runtime Usage

All components are accessed through the singleton InjectionContainer, ensuring consistent instances throughout the application lifecycle.

## Testing Strategy

### Unit Testing

Each layer can be tested independently:

1. **Domain Layer**: Test use cases and entities in isolation
2. **Data Layer**: Test repository implementations with mocked data sources
3. **Presentation Layer**: Test providers with mocked use cases

### Integration Testing

Test the interaction between layers:

1. Data source to repository integration
2. Repository to use case integration
3. Use case to provider integration

## Extensibility

### Adding New Features

1. Create new entities in the domain layer
2. Extend repository interfaces
3. Implement new data sources
4. Create new use cases
5. Update providers and UI

### Swapping Implementations

1. Create new data source implementations
2. Update injection container to use new implementations
3. No changes required in domain or presentation layers

## Performance Considerations

### Memory Management

- Singletons ensure optimal memory usage
- Proper disposal of resources in `close()` methods
- Efficient cache management with size limits

### Concurrency

- Thread-safe singleton implementations
- Async-safe initialization patterns
- Proper error handling in concurrent scenarios

## Conclusion

This architecture provides a robust, maintainable, and scalable foundation for the Flutter Image Gallery application. The singleton pattern ensures efficient resource usage while maintaining clean separation of concerns across architectural layers.