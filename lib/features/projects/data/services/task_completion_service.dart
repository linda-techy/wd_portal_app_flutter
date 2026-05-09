import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/features/projects/data/models/pending_approval_row.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:dio/dio.dart';

/// Dio + Outbox client for the S3 PR2 completion-gate endpoints.
///
/// Site-engineer flow ([markCompleteQueued]) goes through [OutboxService] so
/// it survives offline use. PM flows ([approve], [reject],
/// [pendingApprovalInbox]) stay synchronous because PMs are office-bound and
/// outside the S5 offline scope.
class TaskCompletionService {
  TaskCompletionService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio,
        _outbox = null,
        _sync = null;

  /// Constructor used by the site-engineer flow + tests. PR2 binding.
  TaskCompletionService.forOutbox({
    required OutboxService outbox,
    required SyncService sync,
    ApiService? api,
    Dio? dio,
  })  : _api = api ?? ApiService(),
        _injectedDio = dio,
        _outbox = outbox,
        _sync = sync;

  final ApiService _api;
  final Dio? _injectedDio;
  final OutboxService? _outbox;
  final SyncService? _sync;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// Site-engineer flow. Enqueues the mark-complete via the outbox; SyncService
  /// dispatches it when online. The local task view should treat the task as
  /// PENDING_SYNC until SyncService reports DONE — at which point the
  /// server-side status (PENDING_PM_APPROVAL or COMPLETED) becomes visible on
  /// the next refresh.
  Future<void> markCompleteQueued({
    required int taskId,
    required int? projectId,
    required PhotoCapture photo,
  }) async {
    final outbox = _outbox;
    final sync = _sync;
    if (outbox == null || sync == null) {
      throw StateError(
        'markCompleteQueued requires TaskCompletionService.forOutbox(...).',
      );
    }
    await outbox.enqueue(
      type: OutboxMutationType.taskMarkComplete,
      payload: {'taskId': taskId},
      projectId: projectId,
      taskId: taskId,
      photo: photo,
    );
    // Best-effort kick. Doesn't await — the sync is fire-and-forget.
    // ignore: discarded_futures
    sync.triggerSyncNow();
  }

  /// Deprecated. Pre-PR2 contract returned the new task status, but S3 PR2
  /// mandates geotagged photo evidence which the bare-int signature cannot
  /// carry. Use [markCompleteQueued] instead.
  @Deprecated('Use markCompleteQueued (S5 PR2). Photo evidence is mandatory.')
  Future<String> markComplete(int taskId) {
    throw UnsupportedError(
      'TaskCompletionService.markComplete(int) is removed in S5 PR2. '
      'Call markCompleteQueued({taskId, projectId, photo}) instead.',
    );
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
