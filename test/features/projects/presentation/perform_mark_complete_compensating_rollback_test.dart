import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/features/projects/domain/mark_complete_outcome.dart';
import 'package:admin/features/projects/presentation/screens/perform_mark_complete.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/site_report_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class _OkPicker implements ImagePicker {
  _OkPicker(this.dir);
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
    final f = File(p.join(dir.path, 'shot.jpg'))..writeAsStringSync('jpg');
    return XFile(f.path);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _OfflineProbe implements ConnectivityProbe {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

/// A TaskCompletionService whose markCompleteQueued always throws — used to
/// simulate a failed second enqueue while the FIRST (siteReportCreate) row
/// has already landed in the outbox.
class _FailingTaskCompletion implements TaskCompletionService {
  @override
  Future<int> markCompleteQueued(
          {required int taskId, required int? projectId}) async =>
      throw StateError('simulated outbox failure on second enqueue');
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test(
      'second-enqueue failure deletes the first report row (compensating rollback)',
      () async {
    final tmp = await Directory.systemTemp.createTemp('perform_rollback_');
    final db = OutboxDb(NativeDatabase.memory());
    final outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'photos')),
      uuid: const Uuid(),
    );
    final sync = SyncService(
      outbox: outbox,
      connectivity: ConnectivityService(probe: _OfflineProbe()),
      dio: Dio(),
      uuid: const Uuid(),
    );

    try {
      final perform = buildPerformMarkComplete(
        outbox: outbox,
        // Mark-complete enqueue throws.
        taskCompletionService: _FailingTaskCompletion(),
        // Real site-report service so the FIRST enqueue actually lands.
        siteReportService:
            SiteReportService.forOutbox(outbox: outbox, sync: sync),
        picker: _OkPicker(tmp),
        locationFetcher: () async => Position(
          latitude: 12.97,
          longitude: 77.59,
          accuracy: 5.0,
          timestamp: DateTime.utc(2026, 5, 10),
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      // Sanity: outbox starts empty.
      expect(await db.select(db.outboxEntries).get(), isEmpty);

      final outcome = await perform(42, 7);
      expect(outcome, isA<MarkCompleteFailed>());
      expect((outcome as MarkCompleteFailed).reason,
          MarkCompleteError.outboxFailure);

      // The site-report row that was enqueued first must be GONE
      // (compensating rollback ran).
      final remaining = await db.select(db.outboxEntries).get();
      expect(remaining, isEmpty,
          reason:
              'compensating rollback deletes the report row when mark-complete enqueue fails');

      // Sanity: ensure no stranded row of either type remains.
      final byType = remaining
          .where((r) =>
              r.mutationType == OutboxMutationType.siteReportCreate.toWire() ||
              r.mutationType == OutboxMutationType.taskMarkComplete.toWire())
          .toList();
      expect(byType, isEmpty);
    } finally {
      sync.dispose();
      await db.close();
      try {
        await tmp.delete(recursive: true);
      } on FileSystemException {
        // Windows file-handle race — ignore.
      }
    }
  });
}
