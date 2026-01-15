import 'package:admin/services/api_service.dart';
import '../models/material_indent.dart';
import '../models/vendor_quotation.dart';

class MaterialIndentService {
  final ApiService _apiService = ApiService();

  Future<MaterialIndent> createIndent(
      int projectId, MaterialIndent indent) async {
    try {
      final response = await _apiService.post(
        '/api/indents/project/$projectId',
        data: indent.toJson(),
      );
      if (response.data['success']) {
        return MaterialIndent.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<List<MaterialIndent>> getIndents(int projectId) async {
    try {
      final response = await _apiService.get(
        '/api/indents',
        queryParams: {'projectId': projectId, 'limit': 100},
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

  Future<VendorQuotation> createQuotation(
      int indentId, int vendorId, VendorQuotation quotation) async {
    try {
      final response = await _apiService.post(
        '/api/procurement/quotations/indent/$indentId/vendor/$vendorId',
        data: quotation.toJson(),
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
      final response = await _apiService.get(
        '/api/procurement/quotations/indent/$indentId',
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
      final response = await _apiService.post(
        '/api/procurement/quotations/$quotationId/select',
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
