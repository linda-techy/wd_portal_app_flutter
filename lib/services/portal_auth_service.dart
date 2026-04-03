import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:admin/config/app_config.dart';
import '../models/auth_models.dart';
import '../providers/portal_auth_provider.dart';
import '../providers/permission_provider.dart';
import '../utils/navigation_service.dart';
import 'storage_service.dart';

class PortalAuthService {
  // Use environment-aware base URL
  static final String baseUrl = AppConfig.fullApiUrl;
  // Platform-conditional storage
  static final StorageService _storage = StorageService();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Initialize with auth interceptor
  static void initialize() {
    _dio.interceptors.add(PortalAuthInterceptor(_dio));
  }

  // Login
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      final loginResponse = LoginResponse.fromJson(response.data);

      // Store tokens securely
      await _storage.write(
          key: 'access_token', value: loginResponse.accessToken);
      await _storage.write(
          key: 'refresh_token', value: loginResponse.refreshToken);
      await _storage.write(
          key: 'user_info', value: jsonEncode(loginResponse.user.toJson()));
      await _storage.write(
          key: 'permissions', value: loginResponse.permissions.join(','));

      return loginResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Please check your input');
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } catch (_) {
      throw Exception('An unexpected error occurred');
    }
  }

  // Refresh token
  static Future<RefreshTokenResponse> refreshToken(
      RefreshTokenRequest request) async {
    try {
      final response =
          await _dio.post('/auth/refresh-token', data: request.toJson());
      final refreshResponse = RefreshTokenResponse.fromJson(response.data);

      // Update stored tokens
      await _storage.write(
          key: 'access_token', value: refreshResponse.accessToken);
      if (refreshResponse.refreshToken.isNotEmpty) {
        await _storage.write(
            key: 'refresh_token', value: refreshResponse.refreshToken);
      }

      return refreshResponse;
    } on DioException catch (_) {
      throw Exception('Token refresh failed');
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Clear all stored data
      await _storage.deleteAll();
    }
  }

  // Get current user
  static Future<UserInfo> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserInfo.fromJson(response.data);
    } on DioException catch (_) {
      throw Exception('Failed to get user information');
    }
  }

  // Get stored user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userInfoString = await _storage.read(key: 'user_info');
      if (userInfoString != null && userInfoString.isNotEmpty) {
        return jsonDecode(userInfoString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get stored permissions
  static Future<List<String>> getPermissions() async {
    try {
      final permissionsString = await _storage.read(key: 'permissions');
      if (permissionsString != null && permissionsString.isNotEmpty) {
        return permissionsString.split(',');
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get stored permissions as string
  static Future<String?> getPermissionsString() async {
    try {
      return await _storage.read(key: 'permissions');
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      return accessToken != null;
    } catch (e) {
      return false;
    }
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      return null;
    }
  }

  // Change Password
  static Future<void> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/portal-users/$userId/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data ?? 'Failed to change password');
      }
      rethrow;
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Sends a password-reset email. Always succeeds (backend never reveals
  /// whether the email address is registered, to prevent enumeration).
  static Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data?['error'] ?? 'Invalid email address');
      }
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  /// Validates the reset token and sets a new password.
  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      // Any 2xx is success — check for error body just in case
      if (response.statusCode != 200) {
        throw Exception(response.data?['error'] ?? 'Password reset failed');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'];
      throw Exception(msg ?? 'Password reset failed. Please try again.');
    }
  }

  // Register FCM token with backend (for push notifications)
  static Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post('/auth/portal/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      // Non-critical — token registration failure must not affect app behaviour
    }
  }
}


// Portal-specific auth interceptor (used by PortalAuthService._dio)
class PortalAuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();
  final Dio _dio;
  bool _isRefreshing = false;

  PortalAuthInterceptor(this._dio);

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
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    if (status == 401 && !_isPublicPath(err.requestOptions.path)) {
      if (_isRefreshing) {
        // Already tried refreshing — session is expired.
        await _expireSession();
        _isRefreshing = false;
        return handler.next(err);
      }

      _isRefreshing = true;

      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        await _expireSession();
        _isRefreshing = false;
        return handler.next(err);
      }

      try {
        final response = await _dio.post(
          '/auth/refresh-token',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
        }

        // Retry the original request with the new token.
        final retried = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retried);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — force logout.
        await _expireSession();
        _isRefreshing = false;
        return handler.next(err);
      }
    }

    _isRefreshing = false;
    return handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Clears stored tokens, notifies [PortalAuthProvider] so GoRouter's
  /// refreshListenable fires and redirects to /login automatically.
  Future<void> _expireSession() async {
    await _storage.deleteAll();

    final ctx = NavigationService.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        final permProvider = Provider.of<PermissionProvider>(ctx, listen: false);
        Provider.of<PortalAuthProvider>(ctx, listen: false)
            .forceExpireSession(permissionProvider: permProvider);
      } catch (_) {
        GoRouter.of(ctx).go('/login');
      }
    }

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
