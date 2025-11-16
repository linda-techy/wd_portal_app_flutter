import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => !kReleaseMode;
  static bool get isDebug => kDebugMode;

  // API Configuration
  static const String localApiUrl = 'http://localhost:8080';
  static const String productionApiUrl = 'https://api.walldotbuilders.com';
  static const String apiVersion = '';

  // Get the appropriate API URL based on environment
  static String get apiBaseUrl {
    if (isProduction) {
      return productionApiUrl;
    } else {
      return localApiUrl;
    }
  }

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

  // Print current configuration for debugging
  static void printConfig() {
    if (isDevelopment) {
      print('=== App Configuration ===');
      print('Environment: ${isProduction ? 'Production' : 'Development'}');
      print('API Base URL: $apiBaseUrl');
      print('Full API URL: $fullApiUrl');
      print('Debug Mode: $isDebug');
      print('========================');
    }
  }
}
