import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/features/projects/domain/mark_complete_outcome.dart';
import 'package:admin/features/projects/presentation/screens/perform_mark_complete.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/location_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/site_report_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  test('GPS LocationException → MarkCompleteOutcome.failed(gpsUnavailable) with detail',
      () async {
    final tmp = await Directory.systemTemp.createTemp('perform_gps_');
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
        taskCompletionService:
            TaskCompletionService.forOutbox(outbox: outbox, sync: sync),
        siteReportService:
            SiteReportService.forOutbox(outbox: outbox, sync: sync),
        picker: _OkPicker(tmp),
        locationFetcher: () async =>
            throw LocationException('GPS off in settings'),
      );

      final outcome = await perform(42, 7);
      expect(outcome, isA<MarkCompleteFailed>());
      final f = outcome as MarkCompleteFailed;
      expect(f.reason, MarkCompleteError.gpsUnavailable);
      expect(f.message, 'GPS off in settings');

      final rows = await db.select(db.outboxEntries).get();
      expect(rows, isEmpty);
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
