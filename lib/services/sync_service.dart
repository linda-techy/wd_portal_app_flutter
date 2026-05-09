import 'dart:async';
import 'dart:convert';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Drains the outbox. Triggered by:
///   1. ConnectivityService offline → online transition
///   2. Timer.periodic(Duration(minutes: 5)) (PR1: armed in constructor; not exercised in tests)
///   3. Manual triggerSyncNow()
class SyncService {
  SyncService({
    required OutboxService outbox,
    required ConnectivityService connectivity,
    required Dio dio,
    required Uuid uuid,
  })  : _outbox = outbox,
        _dio = dio,
        _uuid = uuid {
    _connectivitySub = connectivity.watchOnline().listen(_onConnectivity);
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) => triggerSyncNow());
  }

  final OutboxService _outbox;
  final Dio _dio;
  // ignore: unused_field
  final Uuid _uuid; // reserved for PR2 multipart dispatchers

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodic;
  bool _wasOnline = true;
  bool _running = false;

  Future<void> _onConnectivity(bool online) async {
    if (online && !_wasOnline) {
      await triggerSyncNow();
    }
    _wasOnline = online;
  }

  Future<SyncRunSummary> triggerSyncNow() async {
    if (_running) return const SyncRunSummary(0, 0, 0, 0);
    _running = true;
    try {
      final ready = await _outbox.claimReadyForSync(limit: 10);
      var ok = 0, retry = 0, perm = 0;
      for (final entry in ready) {
        final outcome = await _dispatchSafely(entry);
        switch (outcome) {
          case _Outcome.success:
            ok++;
            break;
          case _Outcome.retryable:
            retry++;
            break;
          case _Outcome.permanent:
            perm++;
            break;
        }
      }
      return SyncRunSummary(ready.length, ok, retry, perm);
    } finally {
      _running = false;
    }
  }

  Future<_Outcome> _dispatchSafely(OutboxEntry entry) async {
    await _outbox.markInFlight(entry.id);
    try {
      await _dispatch(entry);
      await _outbox.markDone(entry.id);
      return _Outcome.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && _isRetryableStatus(status)) {
        await _outbox.markRetryable(entry.id,
            httpStatus: status, message: e.message ?? 'http $status');
        return _Outcome.retryable;
      }
      if (status != null && status >= 400 && status < 500) {
        await _outbox.markPermanentFailure(entry.id,
            httpStatus: status, message: e.response?.data?.toString() ?? 'http $status');
        return _Outcome.permanent;
      }
      // network / connection error / no status
      await _outbox.markRetryable(entry.id,
          httpStatus: 0, message: e.message ?? 'network error');
      return _Outcome.retryable;
    }
  }

  static bool _isRetryableStatus(int s) =>
      s == 408 || s == 429 || (s >= 500 && s < 600);

  Future<void> _dispatch(OutboxEntry entry) async {
    final type = OutboxMutationType.fromWire(entry.mutationType);
    final headers = {'Idempotency-Key': entry.clientUuid};
    switch (type) {
      case OutboxMutationType.delayLogCreate:
        final projectId = entry.projectId;
        if (projectId == null) {
          throw StateError('delayLogCreate row missing projectId: ${entry.id}');
        }
        await _dio.post(
          '/api/projects/$projectId/delays',
          data: jsonDecode(entry.payloadJson),
          options: Options(headers: headers),
        );
        return;
      case OutboxMutationType.taskMarkComplete:
      case OutboxMutationType.siteReportCreate:
        // PR1: dispatch shape for these two flows is wired in PR2 (multipart upload).
        throw UnimplementedError(
            'PR2 wires multipart dispatch for ${type.toWire()}');
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodic?.cancel();
  }
}

enum _Outcome { success, retryable, permanent }

class SyncRunSummary {
  const SyncRunSummary(this.claimed, this.succeeded, this.retryable, this.permanent);
  final int claimed;
  final int succeeded;
  final int retryable;
  final int permanent;
}
