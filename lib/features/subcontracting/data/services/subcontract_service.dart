import 'package:admin/services/api_service.dart';
import '../models/subcontract_models.dart';

class SubcontractService {
  final ApiService _apiService = ApiService();

  Future<List<SubcontractWorkOrder>> getProjectWorkOrders(int projectId) async {
    try {
      final response = await _apiService.get(
        '/api/subcontracts/project/$projectId',
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
      final response = await _apiService.post(
        '/api/subcontracts/retention/release',
        data: release.toJson(),
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
