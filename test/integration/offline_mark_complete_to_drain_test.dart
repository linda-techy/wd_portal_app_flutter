import 'dart:async';
import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../test_helpers/mock_dio_adapter.dart';

/// End-to-end coverage for the S5 offline path:
///   1. Site engineer enqueues a `siteReportCreate` (with a photo) followed
///      by a `taskMarkComplete` row while offline.
///   2. Connectivity flips online.
///   3. SyncService.triggerSyncNow drains both rows in id-ASC order.
///   4. Each dispatch sends an Idempotency-Key header.
///   5. Both rows land in DONE; the outbox is empty.
class _ManualProbe implements ConnectivityProbe {
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> initial = [ConnectivityResult.none];
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initial;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;
  void emit(List<ConnectivityResult> r) {
    initial = r;
    _ctrl.add(r);
  }

  Future<void> close() => _ctrl.close();
}

void main() {
  test(
    'markCompleteOffline_whenOnlineAgain_drainsOutboxAndUpdatesTaskStatus',
    () async {
      final tmp = await Directory.systemTemp.createTemp('e2e_offline_drain_');
      final db = OutboxDb(NativeDatabase.memory());
      final outbox = OutboxService(
        db: db,
        photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
        uuid: const Uuid(),
      );
      final probe = _ManualProbe();
      final connectivity = ConnectivityService(probe: probe);
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      final adapter = MockDioAdapter();
      dio.httpClientAdapter = adapter;
      final sync = SyncService(
        outbox: outbox,
        connectivity: connectivity,
        dio: dio,
        uuid: const Uuid(),
      );

      try {
        // Use raw OutboxService.enqueue here rather than the *Service.forOutbox
        // helpers — those eagerly fire `triggerSyncNow` from inside
        // `enqueue`, and we want to control drain timing precisely so we can
        // assert the offline → online drain semantics. The unit tests for
        // each service already cover that the helpers enqueue with the
        // correct shape.

        final tmpPhoto = File(p.join(tmp.path, 'e2e.jpg'))
          ..writeAsStringSync('jpegbytes');
        final photo = PhotoCapture(
          file: tmpPhoto,
          latitude: 12.97,
          longitude: 77.59,
          accuracyMeters: 5.0,
          capturedAt: DateTime.utc(2026, 5, 7),
        );

        await outbox.enqueue(
          type: OutboxMutationType.siteReportCreate,
          payload: {
            'projectId': 3,
            'title': 'COMPLETION photo',
            'description': 'done',
            'reportType': 'COMPLETION',
            'taskId': 7,
            'latitude': 12.97,
            'longitude': 77.59,
            'locationAccuracy': 5.0,
          },
          projectId: 3,
          taskId: 7,
          photo: photo,
        );
        await outbox.enqueue(
          type: OutboxMutationType.taskMarkComplete,
          payload: {'taskId': 7},
          projectId: 3,
          taskId: 7,
          photo: photo,
        );

        // Two rows queued offline.
        final claimed = await outbox.claimReadyForSync(limit: 10);
        expect(claimed, hasLength(2));
        expect(claimed.map((e) => e.state).toSet(),
            {OutboxState.pending.toWire()});

        // Server expectations.
        var reportPosted = false;
        var markCompletePosted = false;
        String? capturedReportKey;
        String? capturedMarkKey;
        adapter.mock('POST', '/api/site-reports', (opts) {
          reportPosted = true;
          capturedReportKey = opts.headers['Idempotency-Key'] as String?;
          return ResponseBody.fromString(
            '{"id":99,"status":"CREATED"}',
            201,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });
        adapter.mock('POST', '/api/tasks/7/mark-complete', (opts) {
          markCompletePosted = true;
          capturedMarkKey = opts.headers['Idempotency-Key'] as String?;
          return ResponseBody.fromString(
            '{"status":"PENDING_PM_APPROVAL"}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        // Flip online + drain.
        probe.emit([ConnectivityResult.wifi]);
        final summary = await sync.triggerSyncNow();

        expect(summary.claimed, 2);
        expect(summary.succeeded, 2);
        expect(summary.retryable, 0);
        expect(summary.permanent, 0);

        expect(reportPosted, isTrue,
            reason: 'site report dispatched at /api/site-reports');
        expect(markCompletePosted, isTrue,
            reason: 'mark-complete dispatched at /api/tasks/7/mark-complete');
        expect(capturedReportKey, isNotNull,
            reason: 'site-report POST must carry an Idempotency-Key header');
        expect(capturedMarkKey, isNotNull,
            reason: 'mark-complete POST must carry an Idempotency-Key header');
        expect(capturedReportKey, isNot(equals(capturedMarkKey)),
            reason: 'each row gets its own clientUuid → distinct keys');

        // Outbox is now empty + done rows are no longer claimable.
        expect(await outbox.claimReadyForSync(limit: 10), isEmpty);
        // And every row landed in DONE.
        final allRows = await outbox.db.select(outbox.db.outboxEntries).get();
        for (final r in allRows) {
          expect(r.state, OutboxState.done.toWire(),
              reason: 'every drained row should land in state DONE');
        }
      } finally {
        sync.dispose();
        await db.close();
        await probe.close();
        try {
          await tmp.delete(recursive: true);
        } on FileSystemException {
          // Best effort — Windows occasionally holds a fd briefly.
        }
      }
    },
  );
}
