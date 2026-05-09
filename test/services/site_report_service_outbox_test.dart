import 'dart:convert';
import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/models/site_report_models.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/site_report_service.dart';
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
  late SiteReportService svc;
  late File photoFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('site_report_outbox_');
    db = OutboxDb(NativeDatabase.memory());
    outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );
    sync = _SpySync();
    svc = SiteReportService.forOutbox(outbox: outbox, sync: sync);
    photoFile = File(p.join(tmp.path, 'p.jpg'))..writeAsStringSync('jpegbytes');
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test(
      'createReportQueued enqueues SITE_REPORT_CREATE with payload + photo + triggers sync',
      () async {
    final photo = PhotoCapture(
      file: photoFile,
      latitude: 12.97,
      longitude: 77.59,
      accuracyMeters: 5.0,
      capturedAt: DateTime.utc(2026, 5, 7, 10),
    );

    final result = await svc.createReportQueued(
      projectId: 3,
      title: 'Footing pour',
      description: 'Done at 10am',
      reportType: ReportType.dailyProgress,
      taskId: 7,
      primaryPhoto: photo,
      latitude: 12.97,
      longitude: 77.59,
      locationAccuracy: 5.0,
    );

    expect(result, isA<SiteReportResultQueued>());

    final rows = await db.select(db.outboxEntries).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.mutationType, OutboxMutationType.siteReportCreate.toWire());
    expect(row.projectId, 3);
    expect(row.taskId, 7);
    expect(row.photoFilePath, isNotNull);

    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    expect(payload['projectId'], 3);
    expect(payload['title'], 'Footing pour');
    expect(payload['description'], 'Done at 10am');
    expect(payload['reportType'], ReportType.dailyProgress.toJson());
    expect(payload['taskId'], 7);
    expect(payload['latitude'], 12.97);
    expect(payload['longitude'], 77.59);
    expect(payload['locationAccuracy'], 5.0);

    expect(sync.triggerSyncNowCalls, 1);
  });

  test('createReportQueued with no photo + no taskId still enqueues', () async {
    final result = await svc.createReportQueued(
      projectId: 3,
      title: 't',
      description: 'd',
      reportType: ReportType.completion,
    );

    expect(result, isA<SiteReportResultQueued>());
    final rows = await db.select(db.outboxEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.photoFilePath, isNull);
    expect(rows.single.taskId, isNull);
  });

  test('legacy createReport throws UnsupportedError', () {
    expect(
      () => svc.createReport(
        projectId: 3,
        title: 't',
        description: 'd',
        reportType: ReportType.dailyProgress,
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('createReportQueued requires forOutbox constructor', () async {
    final defaultSvc = SiteReportService();
    expect(
      () => defaultSvc.createReportQueued(
        projectId: 3,
        title: 't',
        description: 'd',
        reportType: ReportType.dailyProgress,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
