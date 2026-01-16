import 'package:dio/dio.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/http_interceptor.dart';

class UserService {
  static final String baseUrl = AppConfig.fullApiUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static final ApiService _apiService = ApiService();

  static void initialize() {
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  static Future<List<PortalUser>> getAllPortalUsers() async {
    final response = await _apiService.get('/portal-users');
    return _apiService.unwrapList<PortalUser>(
        response, (json) => PortalUser.fromJson(json));
  }

  /// Get portal users filtered by role codes (SALES, CRM, EMPLOYEE)
  static Future<List<PortalUser>> getPortalUsersByRoleCodes(
      List<String> roleCodes) async {
    final queryParams = <String, dynamic>{
      'roleCodes': roleCodes,
    };
    final response = await _apiService.get('/portal-users/by-role-codes',
        queryParams: queryParams);
    return _apiService.unwrapList<PortalUser>(
        response, (json) => PortalUser.fromJson(json));
  }
}
