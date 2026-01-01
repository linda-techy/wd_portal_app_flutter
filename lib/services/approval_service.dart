import 'package:admin/services/api_service.dart';
import 'package:admin/models/approval_models.dart';
import 'package:dio/dio.dart';

class ApprovalService {
  final ApiService _apiService = ApiService();

  Future<ApprovalRequest> createRequest(ApprovalRequest request) async {
    final response = await _apiService.post('/approvals/request', request.toJson());
    return ApprovalRequest.fromJson(response.data);
  }

  Future<ApprovalRequest> processRequest(int requestId, String status, String comments, int approverId) async {
    final response = await _apiService.post(
      '/approvals/process/$requestId',
      {},
      queryParams: {
        'status': status,
        'comments': comments,
        'approverId': approverId,
      },
    );
    return ApprovalRequest.fromJson(response.data);
  }

  Future<List<ApprovalRequest>> getPendingApprovals(int approverId) async {
    final response = await _apiService.get('/approvals/pending/$approverId');
    return (response.data as List).map((r) => ApprovalRequest.fromJson(r)).toList();
  }
}
