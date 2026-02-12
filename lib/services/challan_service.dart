import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/payment_models.dart';

class ChallanService {
  static final ChallanService _instance = ChallanService._internal();
  factory ChallanService() => _instance;

  final ApiService _apiService = ApiService();

  ChallanService._internal();

  /// Search/Filter challans
  Future<List<ChallanItem>> searchChallans({
    String? fy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> body = {};
    if (fy != null) body['fy'] = fy;
    if (startDate != null) body['startDate'] = startDate.toIso8601String();
    if (endDate != null) body['endDate'] = endDate.toIso8601String();

    final response = await _apiService.post('/api/challans/search', data: body);
    
    if (response.data != null) {
      // Direct list response based on controller
      return (response.data as List)
          .map((json) => ChallanItem.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Generate a challan for a transaction
  Future<ChallanItem> generateChallan(int transactionId) async {
    final response = await _apiService.post('/api/challans/generate/$transactionId', data: {});
    
    if (response.data != null) {
      return ChallanItem.fromJson(response.data);
    }
    throw Exception('Failed to generate challan');
  }

  /// Download individual challan PDF
  Future<Uint8List> downloadChallan(int challanId) async {
    final response = await _apiService.get(
      '/api/challans/download/$challanId',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  /// Download bulk challans ZIP
  Future<Uint8List> downloadBulk(List<int> ids) async {
    final response = await _apiService.post(
      '/api/challans/bulk-download',
      data: ids,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}
