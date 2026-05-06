import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/models/cpm_result_model.dart';

void main() {
  group('CpmResultModel.fromJson', () {
    final fixture = <String, dynamic>{
      'projectId': 42,
      'projectStartDate': '2026-06-01',
      'projectFinishDate': '2026-09-30',
      'criticalTaskIds': [101, 103, 107],
      'tasks': [
        {
          'taskId': 101,
          'taskName': 'Site Prep',
          'durationDays': 5,
          'esDate': '2026-06-01',
          'efDate': '2026-06-05',
          'lsDate': '2026-06-01',
          'lfDate': '2026-06-05',
          'totalFloatDays': 0,
          'isCritical': true,
        },
        {
          'taskId': 102,
          'taskName': 'Permit Filing',
          'durationDays': 3,
          'esDate': '2026-06-01',
          'efDate': '2026-06-03',
          'lsDate': '2026-06-04',
          'lfDate': '2026-06-06',
          'totalFloatDays': 3,
          'isCritical': false,
        },
      ],
    };

    test('parses top-level scalar fields', () {
      final result = CpmResultModel.fromJson(fixture);
      expect(result.projectId, 42);
      expect(result.projectStartDate, DateTime.utc(2026, 6, 1));
      expect(result.projectFinishDate, DateTime.utc(2026, 9, 30));
      expect(result.criticalPathTaskIds, [101, 103, 107]);
      expect(result.tasks.length, 2);
    });

    test('parses critical task with float=0', () {
      final result = CpmResultModel.fromJson(fixture);
      expect(result.tasks.first.taskId, 101);
      expect(result.tasks.first.taskName, 'Site Prep');
      expect(result.tasks.first.isCritical, true);
      expect(result.tasks.first.totalFloatDays, 0);
      expect(result.tasks.first.esDate, DateTime.utc(2026, 6, 1));
      expect(result.tasks.first.efDate, DateTime.utc(2026, 6, 5));
    });

    test('parses non-critical task with float and trailing LF', () {
      final result = CpmResultModel.fromJson(fixture);
      expect(result.tasks.last.taskId, 102);
      expect(result.tasks.last.isCritical, false);
      expect(result.tasks.last.totalFloatDays, 3);
      expect(result.tasks.last.efDate, DateTime.utc(2026, 6, 3));
      expect(result.tasks.last.lfDate, DateTime.utc(2026, 6, 6));
    });

    test('byTaskId convenience map keys by taskId', () {
      final result = CpmResultModel.fromJson(fixture);
      final map = result.byTaskId;
      expect(map.length, 2);
      expect(map[101]!.isCritical, true);
      expect(map[102]!.totalFloatDays, 3);
    });

    test('toJson round-trip preserves all fields', () {
      final original = CpmResultModel.fromJson(fixture);
      final reparsed = CpmResultModel.fromJson(original.toJson());
      expect(reparsed.projectId, original.projectId);
      expect(reparsed.criticalPathTaskIds, original.criticalPathTaskIds);
      expect(reparsed.tasks.length, original.tasks.length);
      expect(reparsed.tasks.first.taskId, original.tasks.first.taskId);
      expect(reparsed.tasks.first.isCritical, original.tasks.first.isCritical);
      expect(
        reparsed.tasks.first.esDate.isAtSameMomentAs(original.tasks.first.esDate),
        isTrue,
      );
      expect(
        reparsed.projectFinishDate.isAtSameMomentAs(original.projectFinishDate),
        isTrue,
      );
    });
  });
}
