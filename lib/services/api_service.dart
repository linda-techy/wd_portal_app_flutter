import 'package:dio/dio.dart';
import 'package:admin/services/http_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.fullApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor for bearer token + refresh handling
    _dio.interceptors.add(AuthInterceptor(_dio));

    // Add response interceptor to handle HTML responses
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        // Check if response is HTML instead of JSON
        if (response.data is String &&
            response.data.toString().trim().startsWith('<!DOCTYPE')) {
          throw DioException(
            requestOptions: response.requestOptions,
            error:
                'Server returned HTML instead of JSON. Please check if the API server is running on ${ApiConfig.fullApiUrl}',
            response: response,
            type: DioExceptionType.badResponse,
          );
        }
        handler.next(response);
      },
    ));

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }

  // Generic HTTP methods
  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String endpoint, dynamic data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          // Check if response is HTML instead of JSON
          if (responseData is String &&
              responseData.trim().startsWith('<!DOCTYPE')) {
            return Exception(
                'Server returned HTML instead of JSON. Please check if the API server is running on ${ApiConfig.fullApiUrl}');
          }

          // Handle specific status codes
          switch (statusCode) {
            case 400:
              return Exception('Bad Request: Invalid data provided');
            case 401:
              return Exception('Unauthorized: Please log in again');
            case 403:
              return Exception(
                  'Forbidden: You do not have permission to access this resource');
            case 404:
              return Exception(
                  'Not Found: The requested resource was not found');
            case 500:
              return Exception('Internal Server Error: Please try again later');
            case 502:
              return Exception(
                  'Bad Gateway: Server is temporarily unavailable');
            case 503:
              return Exception(
                  'Service Unavailable: Server is under maintenance');
            default:
              return Exception('Server error: $statusCode');
          }
        case DioExceptionType.connectionError:
          return Exception(
              'Cannot connect to server. Please check if the API server is running on ${ApiConfig.fullApiUrl}');
        case DioExceptionType.cancel:
          return Exception('Request cancelled');
        default:
          return Exception('Network error occurred');
      }
    }
    return Exception('An unexpected error occurred');
  }
}
