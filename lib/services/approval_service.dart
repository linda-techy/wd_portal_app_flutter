import 'package:admin/services/api_service.dart';
import 'package:admin/models/approval_models.dart';

class ApprovalService {
  final ApiService _apiService = ApiService();

  Future<ApprovalRequest> createRequest(ApprovalRequest request) async {
    final response = await _apiService.post('/approvals/request', data: request.toJson());
    return _apiService.unwrap(response, (json) => ApprovalRequest.fromJson(json as Map<String, dynamic>));
  }

  Future<ApprovalRequest> processRequest(int requestId, String status, String comments, int approverId) async {
    final response = await _apiService.post(
      '/approvals/process/$requestId',
      data: {},
      queryParams: {
        'status': status,
        'comments': comments,
        'approverId': approverId,
      },
    );
    return _apiService.unwrap(response, (json) => ApprovalRequest.fromJson(json as Map<String, dynamic>));
  }

  Future<List<ApprovalRequest>> getPendingApprovals(int approverId) async {
    final response = await _apiService.get('/approvals/pending/$approverId');
    return _apiService.unwrapList(response, (json) => ApprovalRequest.fromJson(json));
  }
}
