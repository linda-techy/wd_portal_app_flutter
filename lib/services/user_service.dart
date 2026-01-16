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
    // Dio needs list parameters to be sent as multiple query params with the same key
    // Convert list to Map with List values so Dio sends: ?roleCodes=SALES&roleCodes=CRM&roleCodes=EMPLOYEE
    final queryParams = <String, dynamic>{
      'roleCodes': roleCodes, // Dio will automatically handle List as multiple query params
    };
    try {
      print('Fetching portal users by role codes: $roleCodes');
      final response = await _apiService.get('/portal-users/by-role-codes',
          queryParams: queryParams);
      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      
      final users = _apiService.unwrapList<PortalUser>(
          response, (json) => PortalUser.fromJson(json));
      print('Parsed ${users.length} users');
      return users;
    } catch (e, stackTrace) {
      print('Error in getPortalUsersByRoleCodes: $e');
      print('Stack trace: $stackTrace');
      print('Role codes requested: $roleCodes');
      rethrow;
    }
  }
}
