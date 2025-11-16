import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PortalAuthInterceptor extends Interceptor {
  static const String _accessTokenKey = 'portal_access_token';
  static const String _refreshTokenKey = 'portal_refresh_token';

  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  PortalAuthInterceptor(this._dio) : _storage = const FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token attachment for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh-token')) {
      return handler.next(options);
    }

    // Add access token to request headers
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
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
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken != null) {
          // Attempt to refresh the token
          final response = await _dio.post('/auth/refresh-token', data: {
            'refreshToken': refreshToken,
          });

          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            await _storage.write(key: _accessTokenKey, value: newAccessToken);

            // Retry the original request with new token
            final originalRequest = err.requestOptions;
            originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch(originalRequest);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        // Refresh failed, clear tokens and redirect to login
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
        await _storage.delete(key: 'portal_user_info');
        await _storage.delete(key: 'portal_permissions');
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
