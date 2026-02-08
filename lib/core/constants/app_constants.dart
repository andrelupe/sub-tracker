import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants.
abstract final class AppConstants {
  /// Current application version.
  /// This should match the version in pubspec.yaml.
  static const String version = '2.0.0';

  /// Application name.
  static const String appName = 'SubTracker';

  /// Base URL for the API, loaded from the `.env` file.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5270/api';
}
