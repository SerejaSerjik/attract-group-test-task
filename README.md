# Flutter Image Gallery App

A Flutter application that displays a list of images fetched from the internet with pagination, custom caching, and cache management.

## Features

1. **Image List Display**: Displays images in a responsive grid layout
2. **Pagination**: Implements infinite scrolling to load more images
3. **Custom Image Caching**: Implements a custom caching mechanism without using `cached_network_image`
4. **NoSQL Database**: Uses Hive for storing cached image metadata
5. **Cache Management**: Automatically manages cache size and clears old data when exceeding 1GB

## Project Structure

```
lib/
├── main.dart
├── models/
│   └── image_model.dart
├── services/
│   ├── api_service.dart
│   ├── cache_service.dart
│   └── database_service.dart
├── repositories/
│   └── image_repository.dart
├── providers/
│   └── image_provider.dart
├── utils/
│   └── constants.dart
└── ui/
    ├── screens/
    │   └── home_screen.dart
    ├── widgets/
    │   ├── image_grid_item.dart
    │   └── loading_indicator.dart
    └── themes/
        └── app_theme.dart
```

## Architecture

This project follows a clean architecture pattern with separation of concerns:

- **Models**: Data classes for representing images
- **Services**: Handle API calls, database operations, and caching logic
- **Repositories**: Combine services to provide a unified data access layer
- **Providers**: Manage application state using the Provider package
- **UI**: Contains screens and widgets for the user interface

## Dependencies

- `http`: For making network requests
- `hive`: NoSQL database for local storage
- `hive_flutter`: Flutter integration for Hive
- `path_provider`: For accessing device storage paths
- `provider`: For state management

## Implementation Details

### Custom Caching

The app implements a custom caching mechanism that:

1. Downloads images from the internet
2. Stores them in the device's file system
3. Keeps metadata in a Hive database
4. Tracks cache size and clears old images when exceeding 1GB

### Pagination

The app implements infinite scrolling by:

1. Loading an initial set of images
2. Detecting when the user scrolls to the bottom
3. Automatically loading more images
4. Showing a loading indicator during data fetch

### Cache Management

On app startup, the cache service:

1. Checks the total size of cached images
2. If the size exceeds 1GB, removes the oldest images first
3. Continues removing images until under the limit

## How to Run

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Requirements Fulfilled

✅ Display list/grid of images from public API (Picsum)
✅ Implement pagination with infinite scrolling
✅ Custom caching mechanism without `cached_network_image`
✅ NoSQL database (Hive) for cache storage
✅ Cache size management with 1GB limit
✅ Clean, readable code with proper architecture
✅ Good performance with efficient network and cache usage
✅ Basic but functional UI without obvious bugs

## Possible Improvements

1. Add pull-to-refresh functionality
2. Implement more sophisticated error handling
3. Add image search/filter capabilities
4. Improve UI/UX with animations and transitions
5. Add unit and widget tests
6. Implement offline mode with better cache management