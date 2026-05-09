import 'dart:io';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main() {
  late Directory tmpRoot;
  late OutboxDb db;
  late OutboxService svc;

  setUp(() async {
    tmpRoot = await Directory.systemTemp.createTemp('outbox_test_');
    db = OutboxDb(NativeDatabase.memory());
    svc = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmpRoot.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );
  });

  tearDown(() async {
    await db.close();
    await tmpRoot.delete(recursive: true);
  });

  test('enqueue persists row + writes photo to photoRoot', () async {
    final photoSrc = File(p.join(tmpRoot.path, 'src.jpg'))..writeAsBytesSync([1, 2, 3]);
    final id = await svc.enqueue(
      type: OutboxMutationType.siteReportCreate,
      payload: {'note': 'rain'},
      projectId: 7,
      photo: PhotoCapture(file: photoSrc, capturedAt: DateTime.utc(2026, 5, 7)),
    );

    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.pending.toWire());
    expect(row.mutationType, OutboxMutationType.siteReportCreate.toWire());
    expect(row.photoFilePath, isNotNull);
    expect(File(row.photoFilePath!).existsSync(), isTrue);
    expect(File(row.photoFilePath!).readAsBytesSync(), [1, 2, 3]);
  });

  test('markDone deletes photo file', () async {
    final src = File(p.join(tmpRoot.path, 's.jpg'))..writeAsBytesSync([0]);
    final id = await svc.enqueue(
      type: OutboxMutationType.taskMarkComplete,
      payload: {'taskId': 1},
      photo: PhotoCapture(file: src, capturedAt: DateTime.utc(2026, 5, 7)),
    );
    final before = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(File(before.photoFilePath!).existsSync(), isTrue);

    await svc.markDone(id);

    final after = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(after.state, OutboxState.done.toWire());
    expect(File(before.photoFilePath!).existsSync(), isFalse);
  });

  test('markPermanentFailure preserves photo file', () async {
    final src = File(p.join(tmpRoot.path, 'p.jpg'))..writeAsBytesSync([7]);
    final id = await svc.enqueue(
      type: OutboxMutationType.delayLogCreate,
      payload: {'delayType': 'WEATHER'},
      projectId: 9,
      photo: PhotoCapture(file: src, capturedAt: DateTime.utc(2026, 5, 7)),
    );
    await svc.markPermanentFailure(id, httpStatus: 422, message: 'bad payload');
    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.permanentFailure.toWire());
    expect(row.lastErrorStatus, 422);
    expect(File(row.photoFilePath!).existsSync(), isTrue);
  });

  test('claimReadyForSync filters by state and nextRetryAt', () async {
    // a: PENDING, no retry → eligible
    final aId = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    // b: PENDING, future retry → not eligible
    final bId = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    await svc.markRetryable(bId, httpStatus: 503, message: 'transient');
    // c: DONE → not eligible
    final cId = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    await svc.markDone(cId);

    final ready = await svc.claimReadyForSync(limit: 10);
    expect(ready.map((e) => e.id), contains(aId));
    expect(ready.map((e) => e.id), isNot(contains(bId)));
    expect(ready.map((e) => e.id), isNot(contains(cId)));
  });

  test('startup resets IN_FLIGHT rows back to PENDING', () async {
    final id = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    await svc.markInFlight(id);
    final stuck = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(stuck.state, OutboxState.inFlight.toWire());

    await svc.startup();

    final reset = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(reset.state, OutboxState.pending.toWire());
  });

  test('sweepOrphanedPhotoFiles deletes files with no matching row', () async {
    final orphan = File(p.join(tmpRoot.path, 'outbox', 'photos', 'orphan-uuid.jpg'));
    await orphan.create(recursive: true);
    await orphan.writeAsBytes([42]);
    expect(orphan.existsSync(), isTrue);

    await svc.sweepOrphanedPhotoFiles();

    expect(orphan.existsSync(), isFalse);
  });

  test('markRetryable computes nextRetryAt with exponential backoff capped at 30min', () async {
    final id = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    final t0 = DateTime.now();
    await svc.markRetryable(id, httpStatus: 500, message: 'boom');
    final r1 = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    // attempts=1 → base 2^1 = 2s, plus 0..30s jitter, capped 30min.
    expect(r1.attempts, 1);
    final delta1 = r1.nextRetryAt!.difference(t0);
    expect(delta1.inSeconds, inInclusiveRange(0, 32 + 5));
    // 4th attempt should still be capped at <= 30min (5th would escalate).
    for (var i = 0; i < 3; i++) {
      await svc.markRetryable(id, httpStatus: 500, message: 'boom');
    }
    final r4 = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(r4.attempts, 4);
    expect(r4.nextRetryAt!.difference(DateTime.now()).inMinutes, lessThanOrEqualTo(30));
  });

  test('5th markRetryable escalates to PERMANENT_FAILURE', () async {
    final id = await svc.enqueue(type: OutboxMutationType.delayLogCreate, payload: {});
    for (var i = 0; i < 5; i++) {
      await svc.markRetryable(id, httpStatus: 500, message: 'boom');
    }
    final row = await (db.select(db.outboxEntries)..where((e) => e.id.equals(id))).getSingle();
    expect(row.state, OutboxState.permanentFailure.toWire());
  });
}
