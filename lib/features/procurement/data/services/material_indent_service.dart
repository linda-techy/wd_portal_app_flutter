import 'package:dio/dio.dart';
import '../../../../utils/error_handler.dart'; // Ensure correct path
import '../models/material_indent.dart';
import '../models/vendor_quotation.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/services/auth_service.dart'; // Adjust if using PortalAuthProvider directly or Dio interceptor

class MaterialIndentService {
  final Dio _dio = Dio();
  final String _baseUrl = '${AppConfig.apiBaseUrl}/api/indents';

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
  // Quotation Management

  Future<VendorQuotation> createQuotation(int indentId, int vendorId, VendorQuotation quotation) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/procurement/quotations/indent/$indentId/vendor/$vendorId', // Use distinct endpoint base if needed
        data: quotation.toJson(),
        options: await _getOptions(),
      );
      if (response.data['success']) {
        return VendorQuotation.fromJson(response.data['data']);
      } else {
         throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<VendorQuotation>> getQuotations(int indentId) async {
    try {
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/procurement/quotations/indent/$indentId',
        options: await _getOptions(),
      );
      if (response.data['success']) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => VendorQuotation.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<VendorQuotation> selectQuotation(int quotationId) async {
      try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/procurement/quotations/$quotationId/select',
        options: await _getOptions(),
      );
       if (response.data['success']) {
        return VendorQuotation.fromJson(response.data['data']);
      } else {
         throw Exception(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }
}
