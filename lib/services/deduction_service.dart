import 'package:admin/models/deduction_models.dart';
import 'package:admin/services/api_service.dart';

class DeductionService {
  final ApiService _api = ApiService();

  Future<List<DeductionRegisterEntry>> getByProject(int projectId) async {
    final response = await _api.get('/api/projects/$projectId/deductions');
    final List items =
        (response.data as Map<String, dynamic>)['data'] as List;
    return items
        .map((j) =>
            DeductionRegisterEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<DeductionRegisterEntry> getById(
      int projectId, int deductionId) async {
    final response =
        await _api.get('/api/projects/$projectId/deductions/$deductionId');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return DeductionRegisterEntry.fromJson(data);
  }

  Future<DeductionRegisterEntry> create(
      int projectId, CreateDeductionRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/deductions',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return DeductionRegisterEntry.fromJson(data);
  }

  Future<DeductionRegisterEntry> recordDecision(
      int projectId, int deductionId, DeductionDecisionRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/deductions/$deductionId/decision',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return DeductionRegisterEntry.fromJson(data);
  }

  Future<DeductionRegisterEntry> escalate(
      int projectId, int deductionId, EscalateDeductionRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/deductions/$deductionId/escalate',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return DeductionRegisterEntry.fromJson(data);
  }
}
