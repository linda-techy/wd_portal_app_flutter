import 'package:admin/services/api_service.dart';
import 'package:admin/models/approval_models.dart';
import 'package:admin/models/paginated_response.dart';

class ApprovalService {
  final ApiService _apiService = ApiService();

  Future<ApprovalRequest> createRequest(ApprovalRequest request) async {
    final response =
        await _apiService.post('/approvals/request', data: request.toJson());
    return _apiService.unwrap(response,
        (json) => ApprovalRequest.fromJson(json as Map<String, dynamic>));
  }

  Future<ApprovalRequest> processRequest(
      int requestId, String status, String comments, int approverId) async {
    final response = await _apiService.post(
      '/approvals/process/$requestId',
      data: {},
      queryParams: {
        'status': status,
        'comments': comments,
        'approverId': approverId,
      },
    );
    return _apiService.unwrap(response,
        (json) => ApprovalRequest.fromJson(json as Map<String, dynamic>));
  }

  Future<List<ApprovalRequest>> getPendingApprovals(int approverId) async {
    final response = await _apiService.get('/approvals/pending/$approverId');
    return _apiService.unwrapList(
        response, (json) => ApprovalRequest.fromJson(json));
  }

  /// NEW: Standardized search endpoint for approvals
  Future<PaginatedResponse<ApprovalRequest>> searchApprovals({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response = await _apiService.get('/api/approvals/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<ApprovalRequest>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, ApprovalRequest.fromJson),
    );
  }
}
