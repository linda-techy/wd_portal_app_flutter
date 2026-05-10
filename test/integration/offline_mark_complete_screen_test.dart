import 'dart:async';
import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/features/projects/presentation/screens/perform_mark_complete.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/site_report_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../test_helpers/mock_dio_adapter.dart';

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

class _FakePicker implements ImagePicker {
  _FakePicker(this.dir);
  final Directory dir;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final f = File(p.join(dir.path, 'fake.jpg'))..writeAsStringSync('jpg');
    return XFile(f.path);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test(
    'tapMarkComplete_offline_thenOnline_drainsBothRowsInIdOrderAndUnlinksPhoto',
    () async {
      final tmp =
          await Directory.systemTemp.createTemp('s51_offline_screen_e2e_');
      final photoRoot = Directory(p.join(tmp.path, 'outbox', 'photos'));
      final db = OutboxDb(NativeDatabase.memory());
      final outbox =
          OutboxService(db: db, photoRoot: photoRoot, uuid: const Uuid());
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
        // Pre-stage server stubs: first sync triggered from createReportQueued
        // is fire-and-forget, so we install handlers before invoking the
        // wrapper to avoid 'No mock for ...' errors leaking into the run.
        // The dispatch in this initial call WILL fail because connectivity
        // is offline and SyncService doesn't gate on online state — the row
        // stays PENDING after retry-or-offline-drop. We re-install the
        // online-mode handlers for the explicit drain below.
        adapter.mock('POST', '/api/site-reports', (opts) {
          return ResponseBody.fromString(
            '{"id":99,"status":"CREATED"}',
            201,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });
        adapter.mock('POST', '/api/tasks/7/mark-complete', (opts) {
          return ResponseBody.fromString(
            '{"status":"PENDING_PM_APPROVAL"}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        final perform = buildPerformMarkComplete(
          outbox: outbox,
          taskCompletionService:
              TaskCompletionService.forOutbox(outbox: outbox, sync: sync),
          siteReportService:
              SiteReportService.forOutbox(outbox: outbox, sync: sync),
          picker: _FakePicker(tmp),
          locationFetcher: () async => Position(
            latitude: 12.97,
            longitude: 77.59,
            accuracy: 4.5,
            timestamp: DateTime.utc(2026, 5, 10),
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        // Offline tap. (probe.initial is ConnectivityResult.none.)
        final outcome = await perform(7, 3);
        expect(outcome.runtimeType.toString(), 'MarkCompleteQueued');

        // Wait briefly so the fire-and-forget triggerSyncNow inside
        // createReportQueued/markCompleteQueued lands on something
        // deterministic. With the mocked online dio, the dispatch
        // SUCCEEDS even though connectivity reports offline (SyncService
        // doesn't gate on online state inside triggerSyncNow). That moves
        // both rows to DONE before our explicit drain.
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // 2 rows in id-ASC order (siteReportCreate first).
        final rows = await (db.select(db.outboxEntries)
              ..orderBy([(e) => OrderingTerm.asc(e.id)]))
            .get();
        expect(rows, hasLength(2));
        expect(rows[0].mutationType,
            OutboxMutationType.siteReportCreate.toWire());
        expect(rows[1].mutationType,
            OutboxMutationType.taskMarkComplete.toWire());
        expect(rows[0].id < rows[1].id, isTrue,
            reason: 'siteReportCreate row enqueued first → smaller auto id');

        // siteReportCreate carries the photo + GPS.
        // (After the fire-and-forget sync has succeeded, OutboxService.markDone
        // unlinks the photo file but leaves the photoFilePath column intact;
        // the file-presence assertion is gated on the row state below.)
        expect(rows[0].photoFilePath, isNotNull);
        expect(rows[0].latitude, closeTo(12.97, 0.001));
        expect(rows[0].longitude, closeTo(77.59, 0.001));
        // taskMarkComplete carries neither.
        expect(rows[1].photoFilePath, isNull);
        expect(rows[1].latitude, isNull);

        // If the implicit fire-and-forget sync hasn't finished yet, run a
        // manual drain on top to land both rows in DONE deterministically.
        probe.emit([ConnectivityResult.wifi]);
        final summary = await sync.triggerSyncNow();
        expect(summary.retryable, 0);
        expect(summary.permanent, 0);

        // Both rows landed in DONE (whether by the implicit sync or the
        // manual one above).
        final after = await db.select(db.outboxEntries).get();
        for (final r in after) {
          expect(r.state, OutboxState.done.toWire(),
              reason: 'every drained row should land in state DONE');
        }
        // Photo unlinked on success (markDone contract from PR1).
        final reportPhoto = File(rows[0].photoFilePath!);
        expect(await reportPhoto.exists(), isFalse,
            reason: 'OutboxService.markDone unlinks the file on success');
      } finally {
        sync.dispose();
        await db.close();
        await probe.close();
        try {
          await tmp.delete(recursive: true);
        } on FileSystemException {
          // Best effort — Windows occasionally holds an fd briefly.
        }
      }
    },
  );
}
