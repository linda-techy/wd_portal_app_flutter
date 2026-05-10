import 'dart:io';

import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main() {
  test('deleteEntry removes the row and unlinks the on-disk photo', () async {
    final tmp = await Directory.systemTemp.createTemp('outbox_delete_entry_');
    final photoRoot = Directory(p.join(tmp.path, 'outbox', 'photos'));
    final db = OutboxDb(NativeDatabase.memory());
    final outbox =
        OutboxService(db: db, photoRoot: photoRoot, uuid: const Uuid());

    try {
      final tmpPhoto = File(p.join(tmp.path, 'src.jpg'))
        ..writeAsStringSync('jpegbytes');
      final photo = PhotoCapture(
        file: tmpPhoto,
        capturedAt: DateTime.utc(2026, 5, 10),
        latitude: 12.97,
        longitude: 77.59,
        accuracyMeters: 4.0,
      );

      final id = await outbox.enqueue(
        type: OutboxMutationType.siteReportCreate,
        payload: const {'projectId': 1, 'reportType': 'COMPLETION'},
        projectId: 1,
        taskId: 7,
        photo: photo,
      );

      final beforeRow =
          await (db.select(db.outboxEntries)..where((e) => e.id.equals(id)))
              .getSingleOrNull();
      expect(beforeRow, isNotNull);
      expect(beforeRow!.photoFilePath, isNotNull);
      final copiedPhoto = File(beforeRow.photoFilePath!);
      expect(await copiedPhoto.exists(), isTrue,
          reason: 'enqueue copies the photo into <photoRoot>/<uuid>.jpg');

      await outbox.deleteEntry(id);

      final afterRow =
          await (db.select(db.outboxEntries)..where((e) => e.id.equals(id)))
              .getSingleOrNull();
      expect(afterRow, isNull, reason: 'row removed');
      expect(await copiedPhoto.exists(), isFalse,
          reason: 'on-disk photo unlinked');
    } finally {
      await db.close();
      try {
        await tmp.delete(recursive: true);
      } on FileSystemException {
        // Windows file-handle race — ignore.
      }
    }
  });

  test('deleteEntry on a row without a photo is a no-op for filesystem', () async {
    final tmp = await Directory.systemTemp.createTemp('outbox_delete_entry_np_');
    final db = OutboxDb(NativeDatabase.memory());
    final outbox = OutboxService(
      db: db,
      photoRoot: Directory(p.join(tmp.path, 'outbox', 'photos')),
      uuid: const Uuid(),
    );

    try {
      final id = await outbox.enqueue(
        type: OutboxMutationType.taskMarkComplete,
        payload: const {'taskId': 9},
        projectId: 1,
        taskId: 9,
      );
      await outbox.deleteEntry(id);

      final row =
          await (db.select(db.outboxEntries)..where((e) => e.id.equals(id)))
              .getSingleOrNull();
      expect(row, isNull);
    } finally {
      await db.close();
      try {
        await tmp.delete(recursive: true);
      } on FileSystemException {}
    }
  });
}
