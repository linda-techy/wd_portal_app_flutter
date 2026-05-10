import 'package:admin/data/local/outbox_mutation_type.dart';
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
///
/// FOLLOW-UP (S5 PR2 review, Important #1): [TaskProgressEntryScreen] is the
/// intended call site but has no production wiring today (no router entry,
/// no DI). Wiring also requires reshaping the screen's
/// `onMarkComplete: Future<String> Function(String)` callback to match this
/// service's `Future<void>` shape (server status is no longer available
/// inline; the UI must surface a "queued for sync" state until SyncService
/// reports DONE). Tracked separately — out of scope for PR2.
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
  /// dispatches it when online. Returns the inserted outbox entry id — useful
  /// for compensating rollback (S5.1 dual-row enqueue) and for future
  /// debugging.
  ///
  /// Photo evidence rides on a SEPARATE [OutboxMutationType.siteReportCreate]
  /// row enqueued ahead of this one (via [SiteReportService.createReportQueued]
  /// with [ReportType.completion]). [SyncService] claims rows in id order, so
  /// the report uploads first; the server-side completion-gate query then
  /// succeeds when this row's `/mark-complete` POST runs.
  Future<int> markCompleteQueued({
    required int taskId,
    required int? projectId,
  }) async {
    final outbox = _outbox;
    final sync = _sync;
    if (outbox == null || sync == null) {
      throw StateError(
        'markCompleteQueued requires TaskCompletionService.forOutbox(...).',
      );
    }
    final id = await outbox.enqueue(
      type: OutboxMutationType.taskMarkComplete,
      payload: {'taskId': taskId},
      projectId: projectId,
      taskId: taskId,
    );
    // Best-effort kick. Doesn't await — the sync is fire-and-forget.
    // ignore: discarded_futures
    sync.triggerSyncNow();
    return id;
  }

  /// Deprecated. Pre-PR2 contract returned the new task status, but S3 PR2
  /// mandates geotagged photo evidence which the bare-int signature cannot
  /// carry. Use [markCompleteQueued] instead.
  @Deprecated('Use markCompleteQueued (S5 PR2). Photo evidence is mandatory.')
  Future<String> markComplete(int taskId) {
    throw UnsupportedError(
      'TaskCompletionService.markComplete(int) is removed in S5 PR2. '
      'Call markCompleteQueued({taskId, projectId}) instead — photo '
      'evidence rides on a separate siteReportCreate row.',
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
