import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/config/app_config.dart';

class ApiConnectionTest {
  static final Dio _testDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  /// Test if the API server is reachable and returning JSON
  static Future<ApiConnectionResult> testConnection() async {
    try {
      final response = await _testDio.get('${AppConfig.fullApiUrl}/health');

      if (response.data is String &&
          response.data.toString().trim().startsWith('<!DOCTYPE')) {
        return ApiConnectionResult(
          isConnected: false,
          error:
              'Server returned HTML instead of JSON. The API server may not be running or configured correctly.',
          statusCode: response.statusCode,
        );
      }

      return ApiConnectionResult(
        isConnected: true,
        error: null,
        statusCode: response.statusCode,
        responseData: response.data,
      );
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Connection timeout. The API server may not be running on ${AppConfig.fullApiUrl}';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Cannot connect to API server at ${AppConfig.fullApiUrl}. Please check if the server is running.';
          break;
        case DioExceptionType.badResponse:
          final responseData = e.response?.data;
          if (responseData is String &&
              responseData.trim().startsWith('<!DOCTYPE')) {
            errorMessage =
                'Server returned HTML instead of JSON. The API server may not be running or configured correctly.';
          } else {
            errorMessage = 'Server returned error: ${e.response?.statusCode}';
          }
          break;
        default:
          errorMessage = 'Network error: ${e.message}';
      }

      return ApiConnectionResult(
        isConnected: false,
        error: errorMessage,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiConnectionResult(
        isConnected: false,
        error: 'Unexpected error: $e',
        statusCode: null,
      );
    }
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
