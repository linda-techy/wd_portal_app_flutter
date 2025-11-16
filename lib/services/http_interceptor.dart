import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
      return handler.next(options);
    }

    // Add access token to request
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
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
    if (err.response?.statusCode == 403) {
      // For 403 errors, we don't try to refresh the token as it's a permission issue
      // Just pass the error through with a clear message
      _isRefreshing = false;
      return handler.next(err);
    }

    _isRefreshing = false;
    return handler.next(err);
  }
}
