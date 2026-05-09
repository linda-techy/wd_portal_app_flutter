import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'outbox_db.g.dart';

/// One row per pending mutation produced by a site-engineer flow.
/// See spec at `docs/superpowers/specs/2026-05-07-s5-mobile-offline-outbox-design.md`.
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text().withLength(min: 36, max: 36).unique()();
  TextColumn get mutationType => text().withLength(min: 1, max: 32)();

  IntColumn get projectId => integer().nullable()();
  IntColumn get taskId => integer().nullable()();
  TextColumn get payloadJson => text()();

  TextColumn get photoFilePath => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get gpsAccuracyMeters => real().nullable()();
  DateTimeColumn get capturedAt => dateTime().nullable()();

  TextColumn get state => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  IntColumn get lastErrorStatus => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [OutboxEntries])
class OutboxDb extends _$OutboxDb {
  OutboxDb(super.e);

  /// Convenience constructor used by app boot: opens the canonical
  /// `${appSupportDir}/outbox.sqlite` file.
  OutboxDb.openCanonical() : super(driftDatabase(name: 'outbox'));

  @override
  int get schemaVersion => 1;
}
