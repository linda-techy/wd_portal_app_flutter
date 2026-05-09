import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
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
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('markCompleteQueued enqueues TASK_MARK_COMPLETE + triggers sync',
      () async {
    await svc.markCompleteQueued(taskId: 7, projectId: 3);

    final rows = await db.select(db.outboxEntries).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.mutationType, OutboxMutationType.taskMarkComplete.toWire());
    expect(row.taskId, 7);
    expect(row.projectId, 3);
    expect(row.payloadJson, contains('"taskId":7'));
    // Photo evidence rides on a separate siteReportCreate row, so the
    // mark-complete row carries no photo / GPS columns.
    expect(row.photoFilePath, isNull);
    expect(row.latitude, isNull);
    expect(row.longitude, isNull);

    expect(sync.triggerSyncNowCalls, 1);
  });

  test('legacy markComplete(int) throws UnsupportedError', () {
    expect(() => svc.markComplete(7), throwsA(isA<UnsupportedError>()));
  });

  test('markCompleteQueued requires forOutbox constructor', () async {
    final defaultSvc = TaskCompletionService();
    expect(
      () => defaultSvc.markCompleteQueued(taskId: 7, projectId: 3),
      throwsA(isA<StateError>()),
    );
  });
}
