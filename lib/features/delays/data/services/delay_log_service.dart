import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';

/// PR2 contract: [DelayLogService.logDelayQueued] returns [DelayLogResult].
/// Legacy [logDelay] now throws — call sites must migrate.
sealed class DelayLogResult {
  const DelayLogResult();
}

class DelayLogResultQueued extends DelayLogResult {
  const DelayLogResultQueued(this.outboxEntryId);
  final int outboxEntryId;
}

class DelayLogService {
  DelayLogService()
      : _outbox = null,
        _sync = null;

  /// PR2 binding for the site-engineer flow.
  DelayLogService.forOutbox({
    required OutboxService outbox,
    required SyncService sync,
  })  : _outbox = outbox,
        _sync = sync;

  final ApiService _apiService = ApiService();
  final OutboxService? _outbox;
  final SyncService? _sync;

  Future<List<DelayLog>> getDelays(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/delays');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => DelayLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load delays');
    }
  }

  /// PR2 entry point. Persists the delay log to the outbox; the [SyncService]
  /// dispatches the JSON POST when online.
  Future<DelayLogResult> logDelayQueued(DelayLog delay) async {
    final outbox = _outbox;
    final sync = _sync;
    if (outbox == null || sync == null) {
      throw StateError(
        'logDelayQueued requires DelayLogService.forOutbox(...).',
      );
    }
    final id = await outbox.enqueue(
      type: OutboxMutationType.delayLogCreate,
      payload: delay.toJson(),
      projectId: delay.projectId,
    );
    // ignore: discarded_futures
    sync.triggerSyncNow();
    return DelayLogResultQueued(id);
  }

  /// Deprecated. Pre-PR2 the call site posted directly. Use [logDelayQueued].
  @Deprecated('Use logDelayQueued (S5 PR2).')
  Future<DelayLog> logDelay(DelayLog delay) {
    throw UnsupportedError(
      'DelayLogService.logDelay(DelayLog) is removed in S5 PR2. '
      'Use logDelayQueued(...) which enqueues via the outbox.',
    );
  }

  Future<Map<String, dynamic>> getSummary(int projectId) async {
    final response =
        await _apiService.get('/api/projects/$projectId/delays/summary');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }
    return {};
  }

  Future<DelayLog> closeDelay(
      int projectId, int delayId, DateTime endDate) async {
    final response = await _apiService.put(
      '/api/projects/$projectId/delays/$delayId/close?endDate=${endDate.toIso8601String().substring(0, 10)}',
      data: {},
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(response.data);
    } else {
      throw Exception('Failed to close delay');
    }
  }

  Future<void> deleteDelay(int projectId, int delayId) async {
    final response =
        await _apiService.delete('/api/projects/$projectId/delays/$delayId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete delay');
    }
  }

  /// Standardized search endpoint for delay logs.
  Future<PaginatedResponse<DelayLog>> searchDelayLogs({
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

    final response = await _apiService.get('/api/delay-logs/search',
        queryParams: queryParams);

    final List<dynamic> data = response.data['content'] ?? response.data;
    final items = data.map((json) => DelayLog.fromJson(json)).toList();

    final isLast = response.data['last'] ??
        (page >= (response.data['totalPages'] ?? 1) - 1);
    final isFirst = page == 0;

    return PaginatedResponse<DelayLog>(
      content: items,
      totalElements: response.data['totalElements'] ?? items.length,
      totalPages: response.data['totalPages'] ?? 1,
      currentPage: page,
      pageSize: size,
      isFirst: isFirst,
      isLast: isLast,
      hasNext: !isLast,
      hasPrevious: !isFirst,
    );
  }
}
