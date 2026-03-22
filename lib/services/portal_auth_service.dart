import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:admin/config/app_config.dart';
import '../models/auth_models.dart';
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

  // Register FCM token with backend (for push notifications)
  static Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post('/auth/portal/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      // Non-critical — token registration failure must not affect app behaviour
    }
  }
}


// Portal-specific auth interceptor
class PortalAuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();
  final Dio _dio;
  bool _isRefreshing = false;

  PortalAuthInterceptor(this._dio);

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
          final newRefreshToken = response.data['refreshToken'];
          
          await _storage.write(key: 'access_token', value: newAccessToken);
          if (newRefreshToken != null) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }

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

    _isRefreshing = false;
    return handler.next(err);
  }
}
