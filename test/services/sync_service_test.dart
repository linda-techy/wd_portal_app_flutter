import 'dart:async';
import 'dart:io';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../test_helpers/mock_dio_adapter.dart';

class _FakeProbe implements ConnectivityProbe {
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> initial = [ConnectivityResult.wifi];
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initial;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;
  void emit(List<ConnectivityResult> r) => _ctrl.add(r);
  Future<void> close() => _ctrl.close();
}

void main() {
  late Directory tmp;
  late OutboxDb db;
  late OutboxService outbox;
  late ConnectivityService connectivity;
  late _FakeProbe probe;
  late Dio dio;
  late MockDioAdapter adapter;
  late SyncService sync;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sync_test_');
    db = OutboxDb(NativeDatabase.memory());
    outbox = OutboxService(
        db: db,
        photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
        uuid: const Uuid());
    probe = _FakeProbe();
    connectivity = ConnectivityService(probe: probe);
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    sync = SyncService(outbox: outbox, connectivity: connectivity, dio: dio, uuid: const Uuid());
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
    await tmp.delete(recursive: true);
    await probe.close();
  });

  test('2xx response marks DONE and sends Idempotency-Key header', () async {
    String? capturedKey;
    adapter.mock('POST', '/api/projects/9/delays', (opts) {
      capturedKey = opts.headers['Idempotency-Key'] as String?;
      return ResponseBody.fromString('{"id":42}', 201,
          headers: {
            'content-type': ['application/json']
          });
    });
    final id = await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate,
        payload: {'delayType': 'WEATHER'},
        projectId: 9);

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.done.toWire());
    expect(capturedKey, row.clientUuid);
  });

  test('5xx response marks RETRYABLE with future nextRetryAt', () async {
    adapter.mock('POST', '/api/projects/9/delays',
        (_) => ResponseBody.fromString('{"err":"boom"}', 503, headers: {
              'content-type': ['application/json']
            }));
    final id = await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate,
        payload: {'delayType': 'WEATHER'},
        projectId: 9);

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.pending.toWire());
    expect(row.attempts, 1);
    expect(row.nextRetryAt!.isAfter(DateTime.now()), isTrue);
  });

  test('4xx (other) response marks PERMANENT_FAILURE', () async {
    adapter.mock('POST', '/api/projects/9/delays',
        (_) => ResponseBody.fromString('{"err":"bad"}', 422, headers: {
              'content-type': ['application/json']
            }));
    final id = await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate, payload: {}, projectId: 9);

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.permanentFailure.toWire());
    expect(row.lastErrorStatus, 422);
  });

  test('Network error marks RETRYABLE', () async {
    adapter.mock('POST', '/api/projects/9/delays', (opts) {
      throw DioException(
        requestOptions: opts,
        type: DioExceptionType.connectionError,
        error: const SocketException('no net'),
      );
    });
    final id = await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate, payload: {}, projectId: 9);

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.pending.toWire());
    expect(row.attempts, 1);
  });

  test('5 retryable failures escalate to PERMANENT_FAILURE', () async {
    adapter.mock('POST', '/api/projects/9/delays',
        (_) => ResponseBody.fromString('{}', 500, headers: {
              'content-type': ['application/json']
            }));
    final id = await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate, payload: {}, projectId: 9);

    // Force-claim every pass by zeroing nextRetryAt between attempts.
    for (var i = 0; i < 5; i++) {
      await (db.update(db.outboxEntries)..where((e) => e.id.equals(id)))
          .write(const OutboxEntriesCompanion(nextRetryAt: Value(null)));
      await sync.triggerSyncNow();
    }

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.permanentFailure.toWire());
  });

  test('connectivity offline → online auto-triggers a sync', () async {
    var calls = 0;
    adapter.mock('POST', '/api/projects/9/delays', (_) {
      calls++;
      return ResponseBody.fromString('{"id":1}', 201, headers: {
        'content-type': ['application/json']
      });
    });
    await outbox.enqueue(
        type: OutboxMutationType.delayLogCreate, payload: {}, projectId: 9);

    // Simulate offline → online flip.
    probe.emit([ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    probe.emit([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(calls, 1);
  });
}
