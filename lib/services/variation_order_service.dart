import 'package:admin/models/variation_order_models.dart';
import 'package:admin/services/api_service.dart';

class VariationOrderService {
  final ApiService _api = ApiService();

  // ---- List ----

  Future<List<VariationOrderSummary>> listByProject(int projectId) async {
    final response =
        await _api.get('/api/projects/$projectId/variation-orders');
    final data = response.data as Map<String, dynamic>;
    final List items = data['data'] ?? response.data;
    return items
        .map((j) => VariationOrderSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---- Detail ----

  Future<VariationOrderDetail> getDetail(int projectId, int voId) async {
    final response =
        await _api.get('/api/projects/$projectId/variation-orders/$voId');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return VariationOrderDetail.fromJson(data);
  }

  // ---- Create ----

  Future<VariationOrderSummary> create(
      int projectId, CreateVariationOrderRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/variation-orders',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return VariationOrderSummary.fromJson(data);
  }

  // ---- Submit ----

  Future<VariationOrderSummary> submit(int projectId, int voId) async {
    final response = await _api.post(
      '/api/projects/$projectId/variation-orders/$voId/submit',
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return VariationOrderSummary.fromJson(data);
  }

  // ---- Approve / reject / escalate / return ----

  Future<VariationOrderSummary> processApproval(
      int projectId, int voId, VOApprovalRequest req) async {
    final response = await _api.post(
      '/api/projects/$projectId/variation-orders/$voId/approve',
      data: req.toJson(),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return VariationOrderSummary.fromJson(data);
  }

  // ---- Approval history ----

  Future<List<ApprovalHistoryEntry>> getApprovalHistory(
      int projectId, int voId) async {
    final response = await _api.get(
      '/api/projects/$projectId/variation-orders/$voId/approval-history',
    );
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data
        .map((j) => ApprovalHistoryEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
