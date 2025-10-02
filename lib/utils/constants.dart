class Constants {
  // Picsum API (for infinite scroll)
  static const int imagesPerPage = 30;
  static const int maxCacheSizeBytes = 1073741824; // 1GB
  static const String apiBaseUrl = 'https://picsum.photos';
  static const String apiPhotosEndpoint = '/v2/list';
  // Note: Using public Picsum API (no auth required)

  // UI settings
  static const Duration imageFadeDuration = Duration(milliseconds: 300);
}
