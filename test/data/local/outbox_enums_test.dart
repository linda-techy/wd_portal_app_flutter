import 'package:admin/data/local/outbox_mutation_type.dart';
import 'package:admin/data/local/outbox_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboxMutationType', () {
    test('toWire maps to UPPER_SNAKE strings', () {
      expect(OutboxMutationType.taskMarkComplete.toWire(), 'TASK_MARK_COMPLETE');
      expect(OutboxMutationType.siteReportCreate.toWire(), 'SITE_REPORT_CREATE');
      expect(OutboxMutationType.delayLogCreate.toWire(), 'DELAY_LOG_CREATE');
    });

    test('fromWire roundtrips', () {
      for (final t in OutboxMutationType.values) {
        expect(OutboxMutationType.fromWire(t.toWire()), t);
      }
    });
  });

  group('OutboxState', () {
    test('toWire maps to UPPER_SNAKE strings', () {
      expect(OutboxState.pending.toWire(), 'PENDING');
      expect(OutboxState.inFlight.toWire(), 'IN_FLIGHT');
      expect(OutboxState.permanentFailure.toWire(), 'PERMANENT_FAILURE');
      expect(OutboxState.done.toWire(), 'DONE');
    });

    test('fromWire roundtrips', () {
      for (final s in OutboxState.values) {
        expect(OutboxState.fromWire(s.toWire()), s);
      }
    });
  });
}
