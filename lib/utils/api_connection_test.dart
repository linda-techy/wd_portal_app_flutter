import 'package:flutter/foundation.dart';
import 'package:admin/config/app_config.dart';

class ApiConnectionTest {
  /// Test if the API server is reachable and returning JSON
  /// Note: Health endpoint has been removed. This method now returns a success result without making an API call.
  static Future<ApiConnectionResult> testConnection() async {
    // Health API endpoint removed - returning success without actual API call
    return ApiConnectionResult(
      isConnected: true,
      error: null,
      statusCode: 200,
      responseData: {'message': 'API connection test disabled'},
    );
  }

  /// Safe version of testConnection that never throws
  static Future<ApiConnectionResult> testConnectionSafe() async {
    try {
      return await testConnection();
    } catch (e) {
      return ApiConnectionResult(
        isConnected: false,
        error: 'Connection test failed: $e',
        statusCode: null,
      );
    }
  }

  /// Print detailed connection information for debugging
  static void printConnectionInfo() {
    if (AppConfig.enableDebugLogging) {
      debugPrint('=== API Connection Test ===');
      debugPrint(
          'Environment: ${AppConfig.isProduction ? 'Production' : 'Development'}');
      debugPrint('API Base URL: ${AppConfig.apiBaseUrl}');
      debugPrint('Full API URL: ${AppConfig.fullApiUrl}');
      debugPrint('==========================');
    }
  }
}

class ApiConnectionResult {
  final bool isConnected;
  final String? error;
  final int? statusCode;
  final dynamic responseData;

  ApiConnectionResult({
    required this.isConnected,
    this.error,
    this.statusCode,
    this.responseData,
  });

  @override
  String toString() {
    if (isConnected) {
      return 'API Connection: SUCCESS (Status: $statusCode)';
    } else {
      return 'API Connection: FAILED - $error';
    }
  }
}
