import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Spy SyncService that records triggerSyncNow calls without making any
/// network requests. Constructed without a connectivity stream so the test
/// can stay synchronous and deterministic.
class _SpySync implements SyncService {
  int triggerSyncNowCalls = 0;
  @override
  Future<SyncRunSummary> triggerSyncNow() async {
    triggerSyncNowCalls++;
    return const SyncRunSummary(0, 0, 0, 0);
  }

  @override
  void dispose() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tmp;
  late OutboxDb db;
  late OutboxService outbox;
  late _SpySync sync;
  late TaskCompletionService svc;
  late File photoFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('task_completion_outbox_');
    db = OutboxDb(NativeDatabase.memory());
    outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );
    sync = _SpySync();
    svc = TaskCompletionService.forOutbox(outbox: outbox, sync: sync);
    photoFile = File(p.join(tmp.path, 'evidence.jpg'))
      ..writeAsStringSync('jpegbytes');
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('markCompleteQueued enqueues TASK_MARK_COMPLETE with photo + triggers sync',
      () async {
    final photo = PhotoCapture(
      file: photoFile,
      latitude: 12.97,
      longitude: 77.59,
      accuracyMeters: 8.0,
      capturedAt: DateTime.utc(2026, 5, 7, 10),
    );

    await svc.markCompleteQueued(taskId: 7, projectId: 3, photo: photo);

    final rows = await db.select(db.outboxEntries).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.mutationType, OutboxMutationType.taskMarkComplete.toWire());
    expect(row.taskId, 7);
    expect(row.projectId, 3);
    expect(row.payloadJson, contains('"taskId":7'));
    expect(row.photoFilePath, isNotNull);
    expect(row.latitude, 12.97);
    expect(row.longitude, 77.59);

    expect(sync.triggerSyncNowCalls, 1);
  });

  test('legacy markComplete(int) throws UnsupportedError', () {
    expect(() => svc.markComplete(7), throwsA(isA<UnsupportedError>()));
  });

  test('markCompleteQueued requires forOutbox constructor', () async {
    final defaultSvc = TaskCompletionService();
    final photo = PhotoCapture(
      file: photoFile,
      capturedAt: DateTime.utc(2026, 5, 7),
    );
    expect(
      () => defaultSvc.markCompleteQueued(
        taskId: 7,
        projectId: 3,
        photo: photo,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
