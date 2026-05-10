import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class _OfflineProbe implements ConnectivityProbe {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void main() {
  test('markCompleteQueued returns the inserted outbox entry id', () async {
    final tmp = await Directory.systemTemp.createTemp('mc_returns_id_');
    final db = OutboxDb(NativeDatabase.memory());
    final outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'photos')),
      uuid: const Uuid(),
    );
    final connectivity = ConnectivityService(probe: _OfflineProbe());
    final sync = SyncService(
      outbox: outbox,
      connectivity: connectivity,
      dio: Dio(),
      uuid: const Uuid(),
    );

    try {
      final svc = TaskCompletionService.forOutbox(outbox: outbox, sync: sync);
      final id = await svc.markCompleteQueued(taskId: 42, projectId: 9);

      expect(id, isPositive,
          reason: 'returned id is the auto-generated outbox row primary key');

      final row =
          await (db.select(db.outboxEntries)..where((e) => e.id.equals(id)))
              .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.mutationType, OutboxMutationType.taskMarkComplete.toWire());
      expect(row.taskId, 42);
      expect(row.projectId, 9);
    } finally {
      sync.dispose();
      await db.close();
      try {
        await tmp.delete(recursive: true);
      } on FileSystemException {}
    }
  });
}
