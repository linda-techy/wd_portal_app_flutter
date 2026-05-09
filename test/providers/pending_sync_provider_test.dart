import 'dart:async';
import 'dart:io';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/providers/pending_sync_provider.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class _FakeProbe implements ConnectivityProbe {
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;
  Future<void> close() => _ctrl.close();
}

void main() {
  test('pendingCount reflects outbox enqueues', () async {
    final tmp = await Directory.systemTemp.createTemp('psp_');
    final db = OutboxDb(NativeDatabase.memory());
    final outbox = OutboxService(
        db: db,
        photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
        uuid: const Uuid());
    final probe = _FakeProbe();
    final sync = SyncService(
        outbox: outbox,
        connectivity: ConnectivityService(probe: probe),
        dio: Dio(),
        uuid: const Uuid());
    final provider = PendingSyncProvider(outbox: outbox, sync: sync);

    expect(provider.pendingCount, 0);
    await outbox.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(provider.pendingCount, 1);

    sync.dispose();
    provider.dispose();
    await probe.close();
    await db.close();
    await tmp.delete(recursive: true);
  });
}
