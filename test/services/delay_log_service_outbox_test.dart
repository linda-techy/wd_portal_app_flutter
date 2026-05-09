import 'dart:convert';
import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/features/delays/data/services/delay_log_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

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
  late DelayLogService svc;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('delay_log_outbox_');
    db = OutboxDb(NativeDatabase.memory());
    outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );
    sync = _SpySync();
    svc = DelayLogService.forOutbox(outbox: outbox, sync: sync);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('logDelayQueued enqueues DELAY_LOG_CREATE with toJson body, no photo',
      () async {
    final delay = DelayLog(
      projectId: 3,
      delayType: 'WEATHER',
      fromDate: DateTime.utc(2026, 5, 7),
      reasonText: 'Heavy rain',
    );

    final result = await svc.logDelayQueued(delay);
    expect(result, isA<DelayLogResultQueued>());

    final rows = await db.select(db.outboxEntries).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.mutationType, OutboxMutationType.delayLogCreate.toWire());
    expect(row.projectId, 3);
    expect(row.taskId, isNull);
    expect(row.photoFilePath, isNull);

    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    expect(payload['delayType'], 'WEATHER');
    expect(payload['fromDate'], '2026-05-07');
    expect(payload['reasonText'], 'Heavy rain');
    expect((payload['project'] as Map)['id'], 3);

    expect(sync.triggerSyncNowCalls, 1);
  });

  test('legacy logDelay throws UnsupportedError', () {
    final delay = DelayLog(
      projectId: 3,
      delayType: 'WEATHER',
      fromDate: DateTime.utc(2026, 5, 7),
    );
    expect(() => svc.logDelay(delay), throwsA(isA<UnsupportedError>()));
  });

  test('logDelayQueued requires forOutbox constructor', () async {
    final defaultSvc = DelayLogService();
    final delay = DelayLog(
      projectId: 3,
      delayType: 'WEATHER',
      fromDate: DateTime.utc(2026, 5, 7),
    );
    expect(
      () => defaultSvc.logDelayQueued(delay),
      throwsA(isA<StateError>()),
    );
  });
}
