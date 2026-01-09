import 'package:dio/dio.dart';
import 'package:admin/services/http_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/constants.dart';
import 'package:admin/models/api_response.dart';

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
      logPrint: (obj) {
        if (kDebugMode) {
          debugPrint(obj.toString());
        }
      },
    ));
  }

  // Generic HTTP methods
  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response = await _dio.get(endpoint,
          queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String endpoint,
      {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response =
          await _dio.post(endpoint, data: data, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String endpoint,
      {dynamic data, Map<String, dynamic>? queryParams, Options? options}) async {
    try {
      final response =
          await _dio.put(endpoint, data: data, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String endpoint, {Options? options}) async {
    try {
      final response = await _dio.delete(endpoint, options: options);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Extracts data from a standardized ApiResponse or throws if success is false.
  /// This handles both wrapped and unwrapped data for backward compatibility.
  T unwrap<T>(Response response, T Function(Object? json) fromJsonT) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }

    // Check if it's the new ApiResponse format
    if (response.data is Map<String, dynamic> &&
        (response.data as Map).containsKey('success')) {
      final apiResponse = ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT,
      );

      if (apiResponse.success) {
        if (apiResponse.data == null && T != dynamic && T.toString() != 'void') {
          // Some GET active visits might return success:true but data:null
          // We let the caller handle null if T is nullable, but here we provide a hint.
          return null as T;
        }
        return apiResponse.data as T;
      } else {
        throw Exception(apiResponse.message);
      }
    }

    // Fallback for old endpoints (unwrapped data)
    return fromJsonT(response.data);
  }

  /// Version of unwrap for lists of items
  List<T> unwrapList<T>(Response response, T Function(Map<String, dynamic> json) fromJsonT) {
    return unwrap<List<T>>(response, (json) {
      if (json is List) {
        return json.map((item) => fromJsonT(item as Map<String, dynamic>)).toList();
      }
      return [];
    });
  }

  /// Version of unwrap for **paginated** lists (Spring Data Page format)
  /// Extracts list from data.content when API returns Page<T>
  List<T> unwrapPagedList<T>(Response response, T Function(Map<String, dynamic> json) fromJsonT) {
    return unwrap<List<T>>(response, (json) {
      // Handle Spring Data Page format: { content: [...], totalElements: n, ... }
      if (json is Map<String, dynamic> && json.containsKey('content')) {
        final content = json['content'];
        if (content is List) {
          return content.map((item) => fromJsonT(item as Map<String, dynamic>)).toList();
        }
      }
      // Fallback: try treating as direct list
      if (json is List) {
        return json.map((item) => fromJsonT(item as Map<String, dynamic>)).toList();
      }
      return [];
    });
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

          // Extract error message from ApiResponse if available
          String errorMessage = 'An error occurred';
          if (responseData is Map) {
            errorMessage = responseData['message']?.toString() ?? 
                responseData['error']?.toString() ??
                errorMessage;
          } else if (responseData is String) {
            errorMessage = responseData;
          }

          // Handle specific status codes with user-friendly messages
          switch (statusCode) {
            case 400:
              return Exception(errorMessage);
            case 401:
              return Exception('Authentication required. Please log in again.');
            case 403:
              return Exception(
                  'You do not have permission to perform this action.');
            case 404:
              return Exception(errorMessage.contains('error') ? 'Resource not found' : errorMessage);
            case 409:
              return Exception(
                  'This resource already exists. Please check and try again.');
            case 422:
              return Exception('Invalid data provided: $errorMessage');
            case 500:
              return Exception(
                  'Server error occurred. Please try again later.');
            case 502:
              return Exception(
                  'Bad Gateway: Server is temporarily unavailable');
            case 503:
              return Exception(
                  'Service Unavailable: Server is under maintenance');
            default:
              return Exception('Server error ($statusCode): $errorMessage');
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
