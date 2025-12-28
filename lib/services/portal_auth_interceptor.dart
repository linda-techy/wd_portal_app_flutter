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

  final List<Map<String, dynamic>> _requestQueue = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final responseData = err.response?.data;
    if (responseData is String && responseData.trim().startsWith('<!DOCTYPE')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // If we are already refreshing, queue this request
      if (_isRefreshing) {
        _requestQueue.add({
          'options': err.requestOptions,
          'handler': handler,
        });
        return;
      }

      _isRefreshing = true;
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (refreshToken != null) {
        try {
          // Perform the refresh
          final response = await _dio.post('/auth/refresh-token', data: {
            'refreshToken': refreshToken,
          });

          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];

            // Store new tokens
            await _storage.write(key: _accessTokenKey, value: newAccessToken);
            await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

            _isRefreshing = false;

            // 1. Resolve current failed request
            final originalRequest = err.requestOptions;
            originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(originalRequest);
            handler.resolve(retryResponse);

            // 2. Resolve all queued requests
            for (var queuedRequest in _requestQueue) {
              final options = queuedRequest['options'] as RequestOptions;
              final qHandler = queuedRequest['handler'] as ErrorInterceptorHandler;
              
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final response = await _dio.fetch(options);
                qHandler.resolve(response);
              } catch (e) {
                qHandler.next(e as DioException);
              }
            }
            _requestQueue.clear();
            return;
          }
        } catch (e) {
          // Refresh failed (invalid/expired refresh token)
          await _handleLogout();
        }
      } else {
        await _handleLogout();
      }

      _isRefreshing = false;
      _requestQueue.clear();
    }

    handler.next(err);
  }

  Future<void> _handleLogout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: 'portal_user_info');
    await _storage.delete(key: 'portal_permissions');
  }
}
