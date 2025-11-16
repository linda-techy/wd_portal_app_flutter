import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base authentication service that can be extended by portal and customer applications
abstract class BaseAuthService {
  static const String _baseUrl = 'http://localhost:8080/api';

  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  // Abstract methods that must be implemented by subclasses
  String get accessTokenKey;
  String get refreshTokenKey;
  String get userInfoKey;
  String get permissionsKey;
  String get authEndpoint;

  BaseAuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _storage = const FlutterSecureStorage();
  }

  /// Generic login method that can be used by both portal and customer apps
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(authEndpoint, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Store tokens securely
        await _storage.write(key: accessTokenKey, value: data['accessToken']);
        await _storage.write(key: refreshTokenKey, value: data['refreshToken']);

        // Store user info and permissions
        if (data['user'] != null) {
          await _storage.write(
              key: userInfoKey, value: jsonEncode(data['user']));
        }

        if (data['permissions'] != null) {
          await _storage.write(
              key: permissionsKey, value: jsonEncode(data['permissions']));
        }

        return data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  /// Generic token refresh method
  Future<String> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: refreshTokenKey);
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'];
        await _storage.write(key: accessTokenKey, value: newAccessToken);
        return newAccessToken;
      } else {
        throw Exception('Failed to refresh token');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Refresh token is invalid, user needs to login again
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to refresh token');
      }
    }
  }

  /// Generic logout method
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Clear all stored data
      await _storage.delete(key: accessTokenKey);
      await _storage.delete(key: refreshTokenKey);
      await _storage.delete(key: userInfoKey);
      await _storage.delete(key: permissionsKey);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: accessTokenKey);
    return accessToken != null;
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: userInfoKey);
      if (userData != null) {
        return jsonDecode(userData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user permissions
  Future<List<String>> getPermissions() async {
    try {
      final permissionsData = await _storage.read(key: permissionsKey);
      if (permissionsData != null) {
        final List<dynamic> permissions = jsonDecode(permissionsData);
        return permissions.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Helper methods for token management
  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  /// Get Dio instance with current configuration
  Dio get dio => _dio;
}
