import 'package:dio/dio.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/services/portal_auth_service.dart';

class UserService {
  static final String baseUrl = AppConfig.fullApiUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static void initialize() {
    _dio.interceptors.add(PortalAuthInterceptor(_dio));
  }

  static Future<List<PortalUser>> getAllPortalUsers() async {
    try {
      final response = await _dio.get('/portal-users');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PortalUser.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }
}
