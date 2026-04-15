import 'package:admin/models/final_account_models.dart';
import 'package:admin/services/api_service.dart';

class FinalAccountService {
  final ApiService _api = ApiService();

  Future<FinalAccountData> getByProject(int projectId) async {
    final response =
        await _api.get('/api/projects/$projectId/final-account');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return FinalAccountData.fromJson(data);
  }

  Future<FinalAccountData> create(
      int projectId, CreateFinalAccountRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/final-account',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return FinalAccountData.fromJson(data);
  }

  Future<FinalAccountData> updateStatus(
      int projectId, FinalAccountStatusRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/final-account/status',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return FinalAccountData.fromJson(data);
  }

  Future<FinalAccountData> recompute(int projectId) async {
    final response = await _api.post(
      '/api/projects/$projectId/final-account/recompute',
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return FinalAccountData.fromJson(data);
  }

  Future<FinalAccountData> releaseRetention(
      int projectId, ReleaseRetentionRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/final-account/release-retention',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return FinalAccountData.fromJson(data);
  }
}
