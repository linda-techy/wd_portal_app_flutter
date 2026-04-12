import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PortalAuthInterceptor extends Interceptor {
  static const String _accessTokenKey = 'portal_access_token';
  static const String _refreshTokenKey = 'portal_refresh_token';

  final FlutterSecureStorage _storage;
  final Dio _dio;

  /// Non-null while a token refresh is in progress.
  /// Concurrent 401s await this future instead of triggering their own refresh.
  /// Completes with the new access token on success, or null on failure.
  Completer<String?>? _refreshCompleter;

  PortalAuthInterceptor(this._dio) : _storage = const FlutterSecureStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token attachment for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh-token')) {
      return handler.next(options);
    }

    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final responseData = err.response?.data;
    if (responseData is String && responseData.trim().startsWith('<!DOCTYPE')) {
      return handler.next(err);
    }

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // If a refresh is already running, wait for it to complete and retry.
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.next(e as DioException);
        }
      } else {
        return handler.next(err);
      }
    }

    // This coroutine is first — own the refresh.
    _refreshCompleter = Completer<String?>();

    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      await _handleLogout();
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      return handler.next(err);
    }

    try {
      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

        // Unblock all waiters with the new token.
        _refreshCompleter!.complete(newAccessToken);
        _refreshCompleter = null;

        // Retry the original request.
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } else {
        await _handleLogout();
        _refreshCompleter!.complete(null);
        _refreshCompleter = null;
        return handler.next(err);
      }
    } catch (e) {
      await _handleLogout();
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      return handler.next(err);
    }
  }

  Future<void> _handleLogout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: 'portal_user_info');
    await _storage.delete(key: 'portal_permissions');
  }
}
