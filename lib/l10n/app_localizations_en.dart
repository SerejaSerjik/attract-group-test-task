// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Image Gallery';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheTitle => 'Clear Cache';

  @override
  String get clearCacheMessage =>
      'Are you sure you want to clear all image cache? All saved images will be deleted from the device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get cacheCleared => 'Cache cleared successfully!';

  @override
  String get cacheClearing => 'Clearing cache...';

  @override
  String get imagesDeletedFromStorage =>
      '🧹 All images deleted from local storage';
}
