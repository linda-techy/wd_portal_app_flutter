import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../utils/navigation_service.dart';
import 'package:flutter/material.dart'; // Required for Colors and SnackBar
import 'storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh-token') ||
        options.path.contains('/auth/logout')) {
      print('DEBUG Flutter: Skipping token for ${options.path}');
      return handler.next(options);
    }

    // Add access token to request
    print('DEBUG Flutter: Reading token for ${options.path}');
    final accessToken = await _storage.read(key: 'access_token');
    print('DEBUG Flutter: Token value: ${accessToken != null ? "EXISTS (${accessToken.substring(0, 20)}...)" : "NULL"}');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      print('DEBUG Flutter: Added Bearer token to headers');
    } else {
      print('DEBUG Flutter: No token found in storage!');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if response is HTML instead of JSON (common when server is down)
    final responseData = err.response?.data;
    if (responseData is String && responseData.trim().startsWith('<!DOCTYPE')) {
      // Don't try to refresh token if server is returning HTML
      _isRefreshing = false;
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        // Try to refresh the token
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken != null) {
          final response = await _dio.post(
            '/auth/refresh-token',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['accessToken'];
          await _storage.write(key: 'access_token', value: newAccessToken);

          // Retry the original request with new token
          final originalRequest = err.requestOptions;
          originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(originalRequest);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // Refresh failed, clear tokens and redirect to login
        await _storage.deleteAll();
        _isRefreshing = false;
        // You might want to emit an event here to notify the app to redirect to login
      }
    }

    // Handle 403 Forbidden - user doesn't have permission
    // Handle 403 Forbidden - user doesn't have permission
    if (err.response?.statusCode == 403) {
      // Just pass the error through so UI can show permission denied
      // Do NOT delete tokens or logout
      
      // Show global toaster for permission denied
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Access Denied: You do not have permission to view this resource.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      return handler.next(err);
    }

    _isRefreshing = false;
    return handler.next(err);
  }
}
