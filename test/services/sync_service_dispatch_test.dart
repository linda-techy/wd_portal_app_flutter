import 'dart:async';
import 'dart:convert';
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

class _FakeProbe implements ConnectivityProbe {
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> initial = [ConnectivityResult.wifi];
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initial;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;
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
    tmp = await Directory.systemTemp.createTemp('sync_dispatch_');
    db = OutboxDb(NativeDatabase.memory());
    outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );
    probe = _FakeProbe();
    connectivity = ConnectivityService(probe: probe);
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    sync = SyncService(
      outbox: outbox,
      connectivity: connectivity,
      dio: dio,
      uuid: const Uuid(),
    );
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
    await tmp.delete(recursive: true);
    await probe.close();
  });

  test(
      'taskMarkComplete dispatch posts to /api/tasks/{id}/mark-complete with Idempotency-Key',
      () async {
    String? capturedKey;
    adapter.mock('POST', '/api/tasks/7/mark-complete', (opts) {
      capturedKey = opts.headers['Idempotency-Key'] as String?;
      return ResponseBody.fromString(
        '{"status":"PENDING_PM_APPROVAL"}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });

    final id = await outbox.enqueue(
      type: OutboxMutationType.taskMarkComplete,
      payload: {'taskId': 7},
      projectId: 3,
      taskId: 7,
    );

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    expect(row.state, OutboxState.done.toWire());
    expect(capturedKey, row.clientUuid);
  });

  test(
      'siteReportCreate dispatch posts multipart to /api/site-reports with payload + photo',
      () async {
    final photoFile = File(p.join(tmp.path, 'photo.jpg'))
      ..writeAsStringSync('jpegbytes');

    String? capturedKey;
    String? capturedContentType;
    int? capturedStatus;
    adapter.mock('POST', '/api/site-reports', (opts) {
      capturedKey = opts.headers['Idempotency-Key'] as String?;
      capturedContentType = opts.contentType;
      capturedStatus = 201;
      return ResponseBody.fromString(
        '{"id":99,"status":"CREATED"}',
        201,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });

    final id = await outbox.enqueue(
      type: OutboxMutationType.siteReportCreate,
      payload: {
        'projectId': 3,
        'title': 't',
        'description': 'd',
        'reportType': 'DAILY_PROGRESS',
        'taskId': 7,
        'latitude': 12.97,
        'longitude': 77.59,
        'locationAccuracy': 5.0,
      },
      projectId: 3,
      taskId: 7,
      photo: PhotoCapture(
        file: photoFile,
        latitude: 12.97,
        longitude: 77.59,
        accuracyMeters: 5.0,
        capturedAt: DateTime.utc(2026, 5, 7),
      ),
    );

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    expect(row.state, OutboxState.done.toWire());
    expect(capturedKey, row.clientUuid);
    expect(capturedStatus, 201);
    expect(capturedContentType, contains('multipart/form-data'));
  });

  test(
      'delayLogCreate dispatch posts JSON to /api/projects/{id}/delays with Idempotency-Key',
      () async {
    String? capturedKey;
    Map<String, dynamic>? capturedBody;
    adapter.mock('POST', '/api/projects/3/delays', (opts) {
      capturedKey = opts.headers['Idempotency-Key'] as String?;
      capturedBody = opts.data as Map<String, dynamic>?;
      return ResponseBody.fromString(
        '{"id":55}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });

    final id = await outbox.enqueue(
      type: OutboxMutationType.delayLogCreate,
      payload: {
        'project': {'id': 3},
        'delayType': 'WEATHER',
        'fromDate': '2026-05-07',
      },
      projectId: 3,
    );

    await sync.triggerSyncNow();

    final row = await (db.select(db.outboxEntries)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    expect(row.state, OutboxState.done.toWire());
    expect(capturedKey, row.clientUuid);
    expect(capturedBody, isNotNull);
    expect(capturedBody!['delayType'], 'WEATHER');
    expect((capturedBody!['project'] as Map)['id'], 3);
  });

  test('5xx → markRetryable; row stays in outbox PENDING with attempts=1',
      () async {
    adapter.mock(
      'POST',
      '/api/projects/3/delays',
      (_) => ResponseBody.fromString(
        '{"error":"down"}',
        503,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );

    final id = await outbox.enqueue(
      type: OutboxMutationType.delayLogCreate,
      payload: {
        'project': {'id': 3},
        'delayType': 'WEATHER',
        'fromDate': '2026-05-07',
      },
      projectId: 3,
    );

    final summary = await sync.triggerSyncNow();
    expect(summary.retryable, 1);
    expect(summary.succeeded, 0);

    final row = await (db.select(db.outboxEntries)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    expect(row.state, OutboxState.pending.toWire());
    expect(row.attempts, 1);
    expect(row.lastErrorStatus, 503);
  });

  test('payload survives a JSON round-trip through the outbox', () async {
    Map<String, dynamic>? captured;
    adapter.mock('POST', '/api/projects/3/delays', (opts) {
      captured = opts.data as Map<String, dynamic>?;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final original = {
      'project': {'id': 3},
      'delayType': 'WEATHER',
      'fromDate': '2026-05-07',
      'reasonText': 'Heavy rain — site flooded',
    };
    await outbox.enqueue(
      type: OutboxMutationType.delayLogCreate,
      payload: original,
      projectId: 3,
    );
    await sync.triggerSyncNow();
    expect(jsonEncode(captured), jsonEncode(original));
  });
}
