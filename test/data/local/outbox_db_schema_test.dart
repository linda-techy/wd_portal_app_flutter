import 'package:admin/data/local/outbox_db.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OutboxDb schemaVersion is 1', () {
    final db = OutboxDb(NativeDatabase.memory());
    expect(db.schemaVersion, 1);
  });

  test('OutboxEntries declares expected columns', () async {
    final db = OutboxDb(NativeDatabase.memory());
    // forces table creation
    await db.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='outbox_entries'").get();
    final cols = (await db.customSelect("PRAGMA table_info(outbox_entries)").get())
        .map((r) => r.data['name'] as String)
        .toSet();
    expect(cols, containsAll([
      'id', 'client_uuid', 'mutation_type', 'project_id', 'task_id', 'payload_json',
      'photo_file_path', 'latitude', 'longitude', 'gps_accuracy_meters', 'captured_at',
      'state', 'attempts', 'next_retry_at', 'last_error_message', 'last_error_status',
      'created_at', 'updated_at',
    ]));
  });
}
