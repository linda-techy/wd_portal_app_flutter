import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => !kReleaseMode;
  static bool get isDebug => kDebugMode;

  // API Configuration
  // Development: Uses localhost as default fallback (port 8081)
  // Production: Must be set via dart-define: --dart-define=API_BASE_URL=https://api.walldotbuilders.com
  // For release builds, API_BASE_URL should always be provided via dart-define
  static const String _devApiUrl = 'http://localhost:8080';
  static const String _prodApiUrl = 'https://api.walldotbuilders.com';

  // Portal App Base URL
  // Used for full-page redirects (e.g. after session expiry on web).
  // Override via: --dart-define=PORTAL_BASE_URL=https://portal.walldotbuilders.com
  static const String _devPortalUrl = 'http://localhost:3001';
  static const String _prodPortalUrl = 'https://portal.walldotbuilders.com';

  static String get portalBaseUrl {
    const String envPortalUrl = String.fromEnvironment('PORTAL_BASE_URL');
    if (envPortalUrl.isNotEmpty) return envPortalUrl;
    return isProduction ? _prodPortalUrl : _devPortalUrl;
  }

  // Get API URL from environment variable (dart-define) or use defaults
  // In production (kReleaseMode), this will use the dart-define value or production URL
  // In development, this will use the dart-define value or localhost
  static String get apiBaseUrl {
    const String envApiUrl = String.fromEnvironment('API_BASE_URL');
    if (envApiUrl.isNotEmpty) {
      return envApiUrl;
    }
    // Fallback: use production URL in release mode, localhost in development
    return isProduction ? _prodApiUrl : _devApiUrl;
  }

  static const String apiVersion = '';

  static String get fullApiUrl => '$apiBaseUrl$apiVersion';

  // App Configuration
  static const String appName = 'WD Builders Portal';
  static const String appVersion = '1.0.0';

  // Feature Flags
  static bool get enableDebugLogging => isDevelopment;
  static bool get enableAnalytics => isProduction;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx'
  ];

  // Cache Configuration
  static const Duration cacheTimeout = Duration(hours: 1);
  static const int maxCacheSize = 50; // MB

  // Error Reporting
  static bool get enableErrorReporting => isProduction;

  // Development Tools
  static bool get enableDevTools => isDevelopment;

  // Date Picker Configuration
  static final DateTime datePickerFirstDate = DateTime(2020);

  // Print current configuration for debugging
  static void printConfig() {
    if (isDevelopment) {
      // ignore: avoid_print
      debugPrint('=== App Configuration ===');
      // ignore: avoid_print
      debugPrint('Environment: ${isProduction ? 'Production' : 'Development'}');
      // ignore: avoid_print
      debugPrint('API Base URL: $apiBaseUrl');
      // ignore: avoid_print
      debugPrint('Full API URL: $fullApiUrl');
      // ignore: avoid_print
      debugPrint('Debug Mode: $isDebug');
      // ignore: avoid_print
      debugPrint('========================');
    }
  }
}
