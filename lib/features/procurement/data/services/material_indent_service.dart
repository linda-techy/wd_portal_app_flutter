import 'package:dio/dio.dart';
import '../../../../utils/error_handler.dart'; // Ensure correct path
import '../models/material_indent.dart';
import 'package:admin/services/auth_service.dart'; // Adjust if using PortalAuthProvider directly or Dio interceptor

class MaterialIndentService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8080/api/indents'; // Adjust for env

  MaterialIndentService() {
    // Basic setup if not using a centralized Dio client
    // In a real app, use the centralized API client from a provider
     _dio.options.headers['Content-Type'] = 'application/json';
     // Note: Token injection should be handled by an interceptor or passed in
  }

  // Helper to add auth token
  Future<Options> _getOptions({Map<String, dynamic>? headers}) async {
      String? token = await AuthService.getToken(); // Assume this exists
      return Options(headers: {
        'Authorization': 'Bearer $token',
        ...?headers,
      });
  }

  Future<MaterialIndent> createIndent(int projectId, MaterialIndent indent) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/project/$projectId',
        data: indent.toJson(),
        options: await _getOptions(),
      );
      if (response.data['success']) {
        return MaterialIndent.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw e; // Let ErrorHandler catch it in UI
    }
  }

  Future<List<MaterialIndent>> getIndents(int projectId) async {
    try {
      // Assuming search endpoint handles list-by-project
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {'projectId': projectId, 'limit': 100},
        options: await _getOptions(),
      );
      if (response.data['success']) {
        final List<dynamic> list = response.data['data']['content'];
        return list.map((json) => MaterialIndent.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
       throw e;
    }
  }
}
