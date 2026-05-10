import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:admin/data/local/photo_capture.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class OutboxService {
  OutboxService({required OutboxDb db, required Directory photoRoot, required Uuid uuid})
      : _db = db,
        _photoRoot = photoRoot,
        _uuid = uuid;

  final OutboxDb _db;
  final Directory _photoRoot;
  final Uuid _uuid;
  final Random _rng = Random();

  static const int _maxRetryableAttempts = 5;
  static const Duration _maxBackoff = Duration(minutes: 30);

  OutboxDb get db => _db;

  Future<int> enqueue({
    required OutboxMutationType type,
    required Map<String, dynamic> payload,
    int? projectId,
    int? taskId,
    PhotoCapture? photo,
  }) async {
    final clientUuid = _uuid.v4();
    String? photoPath;
    if (photo != null) {
      await _photoRoot.create(recursive: true);
      photoPath = p.join(_photoRoot.path, '$clientUuid.jpg');
      await photo.file.copy(photoPath);
    }

    return _db.into(_db.outboxEntries).insert(OutboxEntriesCompanion.insert(
          clientUuid: clientUuid,
          mutationType: type.toWire(),
          projectId: Value(projectId),
          taskId: Value(taskId),
          payloadJson: jsonEncode(payload),
          photoFilePath: Value(photoPath),
          latitude: Value(photo?.latitude),
          longitude: Value(photo?.longitude),
          gpsAccuracyMeters: Value(photo?.accuracyMeters),
          capturedAt: Value(photo?.capturedAt),
          state: OutboxState.pending.toWire(),
        ));
  }

  Stream<List<OutboxEntry>> watchPending() => (_db.select(_db.outboxEntries)
        ..where((e) =>
            e.state.equals(OutboxState.pending.toWire()) |
            e.state.equals(OutboxState.inFlight.toWire())))
      .watch();

  Stream<List<OutboxEntry>> watchPermanentFailures() => (_db.select(_db.outboxEntries)
        ..where((e) => e.state.equals(OutboxState.permanentFailure.toWire())))
      .watch();

  Stream<int> watchPendingCount() => watchPending().map((rows) => rows.length);

  Future<void> markInFlight(int id) =>
      _patch(id, state: OutboxState.inFlight.toWire());

  Future<void> markDone(int id) async {
    final row = await _byId(id);
    if (row?.photoFilePath != null) {
      final f = File(row!.photoFilePath!);
      if (await f.exists()) await f.delete();
    }
    await _patch(id, state: OutboxState.done.toWire());
  }

  Future<void> markRetryable(int id,
      {required int httpStatus, required String message}) async {
    final row = await _byId(id);
    final attempts = (row?.attempts ?? 0) + 1;
    if (attempts >= _maxRetryableAttempts) {
      await markPermanentFailure(id,
          httpStatus: httpStatus,
          message: 'Escalated after $attempts retryable attempts: $message');
      return;
    }
    final base = pow(2, attempts).toInt();
    final jitter = _rng.nextInt(31); // 0..30s
    final delay = Duration(seconds: base + jitter);
    final clamped = delay > _maxBackoff ? _maxBackoff : delay;
    await _patch(id,
        state: OutboxState.pending.toWire(),
        attempts: attempts,
        nextRetryAt: DateTime.now().add(clamped),
        lastErrorMessage: message,
        lastErrorStatus: httpStatus);
  }

  Future<void> markPermanentFailure(int id,
      {required int httpStatus, required String message}) async {
    await _patch(id,
        state: OutboxState.permanentFailure.toWire(),
        lastErrorMessage: message,
        lastErrorStatus: httpStatus);
  }

  Future<void> discardPermanentFailure(int id) async {
    final row = await _byId(id);
    if (row?.photoFilePath != null) {
      final f = File(row!.photoFilePath!);
      if (await f.exists()) await f.delete();
    }
    await (_db.delete(_db.outboxEntries)..where((e) => e.id.equals(id))).go();
  }

  /// Remove a row + unlink its on-disk photo (if any). Used by the S5.1
  /// mark-complete flow as a compensating rollback when the *second* enqueue
  /// in a paired (siteReportCreate, taskMarkComplete) atomic write fails.
  ///
  /// Differs from [discardPermanentFailure] in two ways:
  ///   1. No state pre-condition — works on any row state.
  ///   2. Used immediately after enqueue (no audit trail needed); whereas
  ///      [discardPermanentFailure] is the user-facing "I give up on this
  ///      row" path triggered from PendingSyncScreen.
  ///
  /// The DB delete must happen even if the photo unlink fails — on Windows
  /// the photo file can be held open by an in-flight SyncService dispatch
  /// (multipart upload reading the file) when the rollback runs concurrently
  /// with a fire-and-forget `triggerSyncNow()` from `createReportQueued`.
  /// Any orphaned photo files are reclaimed by [sweepOrphanedPhotoFiles] on
  /// next startup.
  Future<void> deleteEntry(int id) async {
    final row = await _byId(id);
    if (row?.photoFilePath != null) {
      try {
        final f = File(row!.photoFilePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // File may be locked by an in-flight upload; the DB row still goes.
      }
    }
    await (_db.delete(_db.outboxEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> retryPermanentFailure(int id) => _patch(id,
      state: OutboxState.pending.toWire(),
      attempts: 0,
      nextRetryAt: null,
      lastErrorMessage: null,
      lastErrorStatus: null);

  Future<List<OutboxEntry>> claimReadyForSync({int limit = 10}) {
    final now = DateTime.now();
    return (_db.select(_db.outboxEntries)
          ..where((e) =>
              e.state.equals(OutboxState.pending.toWire()) &
              (e.nextRetryAt.isNull() | e.nextRetryAt.isSmallerOrEqualValue(now)))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Reset rows stuck IN_FLIGHT (e.g. app killed mid-sync) back to PENDING.
  Future<void> startup() async {
    await (_db.update(_db.outboxEntries)
          ..where((e) => e.state.equals(OutboxState.inFlight.toWire())))
        .write(OutboxEntriesCompanion(
            state: Value(OutboxState.pending.toWire()),
            updatedAt: Value(DateTime.now())));
    await sweepOrphanedPhotoFiles();
  }

  /// Delete files in [photoRoot] whose filename UUID is not referenced by any row.
  Future<void> sweepOrphanedPhotoFiles() async {
    if (!await _photoRoot.exists()) return;
    final live = (await _db.select(_db.outboxEntries).get())
        .map((e) => e.clientUuid)
        .toSet();
    await for (final entity in _photoRoot.list()) {
      if (entity is! File) continue;
      final base = p.basenameWithoutExtension(entity.path);
      if (!live.contains(base)) {
        await entity.delete();
      }
    }
  }

  Future<OutboxEntry?> _byId(int id) =>
      (_db.select(_db.outboxEntries)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> _patch(
    int id, {
    String? state,
    int? attempts,
    DateTime? nextRetryAt,
    String? lastErrorMessage,
    int? lastErrorStatus,
  }) async {
    await (_db.update(_db.outboxEntries)..where((e) => e.id.equals(id)))
        .write(OutboxEntriesCompanion(
      state: state == null ? const Value.absent() : Value(state),
      attempts: attempts == null ? const Value.absent() : Value(attempts),
      nextRetryAt: Value(nextRetryAt),
      lastErrorMessage: Value(lastErrorMessage),
      lastErrorStatus: Value(lastErrorStatus),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
