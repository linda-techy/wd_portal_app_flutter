import 'package:dio/dio.dart';
import '../models/subcontract_models.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/services/auth_service.dart';

class SubcontractService {
  final Dio _dio = Dio();
  final String _baseUrl = '${AppConfig.apiBaseUrl}/api/subcontracts'; // Adjust base URL

  SubcontractService() {
     _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<Options> _getOptions() async {
      String? token = await AuthService.getToken();
      return Options(headers: {
        'Authorization': 'Bearer $token',
      });
  }

  Future<List<SubcontractWorkOrder>> getProjectWorkOrders(int projectId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/project/$projectId', // Assuming endpoint exists
        options: await _getOptions(),
      );
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => SubcontractWorkOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw e;
    }
  }

  Future<RetentionRelease> releaseRetention(RetentionRelease release) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/retention/release', // Assuming endpoint
        data: release.toJson(),
        options: await _getOptions(),
      );
       if (response.data['success']) {
        return RetentionRelease.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw e;
    }
  }
}
