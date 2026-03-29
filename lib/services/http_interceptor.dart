import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/portal_auth_provider.dart';
import '../utils/navigation_service.dart';
import 'storage_service.dart';

/// HTTP interceptor for the main [ApiService] Dio instance.
///
/// Responsibilities:
///   1. Inject Bearer token on every non-auth request.
///   2. On 401: attempt silent token refresh once, then retry original request.
///   3. If refresh also fails (or no refresh token): expire the session and
///      redirect to /login via GoRouter (not Navigator 1.0).
///   4. On 403: show a global "permission denied" snack-bar.
class AuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  // ── Public auth paths that should never trigger token injection / 401 loop ──
  static const _publicPaths = [
    '/auth/login',
    '/auth/refresh-token',
    '/auth/logout',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  static bool _isPublicPath(String path) =>
      _publicPaths.any((p) => path.contains(p));

  // ── Request ───────────────────────────────────────────────────────────────

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublicPath(options.path)) {
      return handler.next(options);
    }
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    // ── 403 Forbidden — show snack, pass through ────────────────────────────
    if (status == 403) {
      _showSnackBar('You do not have permission to perform this action.',
          color: Colors.red.shade700);
      _isRefreshing = false;
      return handler.next(err);
    }

    // ── 401 Unauthorized ────────────────────────────────────────────────────
    if (status == 401 && !_isPublicPath(err.requestOptions.path)) {
      if (_isRefreshing) {
        // Already tried refreshing — session is expired, redirect now.
        await _expireSession();
        return handler.next(err);
      }

      _isRefreshing = true;

      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        // No refresh token at all — session expired.
        await _expireSession();
        _isRefreshing = false;
        return handler.next(err);
      }

      try {
        // Attempt silent token refresh.
        final refreshResponse = await _dio.post(
          '/auth/refresh-token',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = refreshResponse.data['accessToken'];
        final newRefreshToken = refreshResponse.data['refreshToken'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
        }

        // Retry original request with the new token.
        final retried = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retried);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — token is truly invalid. Force log out.
        await _expireSession();
        _isRefreshing = false;
        return handler.next(err);
      }
    }

    _isRefreshing = false;
    return handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Clears stored tokens, notifies [PortalAuthProvider] (triggering GoRouter
  /// redirect to /login), and shows a session-expired snack-bar.
  Future<void> _expireSession() async {
    // 1. Clear persisted tokens.
    await _storage.deleteAll();

    // 2. Notify PortalAuthProvider → GoRouter refreshListenable fires → /login.
    final ctx = NavigationService.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        Provider.of<PortalAuthProvider>(ctx, listen: false).forceExpireSession();
      } catch (_) {
        // Provider not available in this context — fall back to direct navigation.
        GoRouter.of(ctx).go('/login');
      }
    }

    // 3. Inform the user.
    _showSnackBar('Your session has expired. Please log in again.',
        color: Colors.orange.shade700);
  }

  void _showSnackBar(String message, {required Color color}) {
    NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
