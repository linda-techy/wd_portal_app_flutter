import 'package:admin/models/stage_payment_models.dart';
import 'package:admin/services/api_service.dart';

class StagePaymentService {
  final ApiService _api = ApiService();

  Future<List<StageTimelineSummary>> getProjectStages(int projectId) async {
    final response = await _api.get('/api/projects/$projectId/stages');
    final List items =
        (response.data as Map<String, dynamic>)['data'] as List;
    return items
        .map((j) => StageTimelineSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<StageCertificationDetail> getStage(
      int projectId, int stageId) async {
    final response =
        await _api.get('/api/projects/$projectId/stages/$stageId');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return StageCertificationDetail.fromJson(data);
  }

  Future<StageCertificationDetail> certify(
      int projectId, int stageId, CertifyStageRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/stages/$stageId/certify',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return StageCertificationDetail.fromJson(data);
  }

  Future<StageCertificationDetail> recordPayment(
      int projectId, int stageId, RecordStagePaymentRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/stages/$stageId/payment',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return StageCertificationDetail.fromJson(data);
  }
}
