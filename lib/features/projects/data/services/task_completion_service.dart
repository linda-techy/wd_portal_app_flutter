import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/projects/data/models/pending_approval_row.dart';

/// Dio client for the S3 PR2 completion-gate endpoints (mirrors the
/// holiday_admin_service / wbs_template_service shape).
class TaskCompletionService {
  final ApiService _api;
  final Dio? _injectedDio;

  TaskCompletionService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// POST /api/tasks/{id}/mark-complete — site engineer flow.
  /// Backend returns the updated Task; we just surface the new status.
  Future<String> markComplete(int taskId) async {
    final r = await _dio.post('/api/tasks/$taskId/mark-complete');
    final body = _api.unwrap(r, (json) => json as Map<String, dynamic>);
    return body['status'] as String;
  }

  /// POST /api/tasks/{id}/approve-completion — PM flow.
  Future<String> approve(int taskId) async {
    final r = await _dio.post('/api/tasks/$taskId/approve-completion');
    final body = _api.unwrap(r, (json) => json as Map<String, dynamic>);
    return body['status'] as String;
  }

  /// POST /api/tasks/{id}/reject-completion — PM flow with reason (>= 5 chars).
  Future<String> reject(int taskId, String reason) async {
    final r = await _dio.post(
      '/api/tasks/$taskId/reject-completion',
      data: {'reason': reason},
    );
    final body = _api.unwrap(r, (json) => json as Map<String, dynamic>);
    return body['status'] as String;
  }

  /// GET /api/tasks/pending-pm-approval — PM inbox.
  Future<List<PendingApprovalRow>> pendingApprovalInbox() async {
    final r = await _dio.get('/api/tasks/pending-pm-approval');
    return _api.unwrapList(r, PendingApprovalRow.fromJson);
  }
}
