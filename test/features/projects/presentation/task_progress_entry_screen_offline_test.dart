import 'package:admin/features/projects/domain/mark_complete_outcome.dart';
import 'package:admin/features/projects/presentation/screens/task_progress_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<TaskRow>> _oneTask(String pid, String f) async => const [
      TaskRow(id: '42', title: 'Beam casting', progressPercent: 50),
    ];

Future<void> _saveProgress(String id, int p, String? n) async {}

Future<void> _openSheetForBeamCasting(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Beam casting'));
  await tester.pumpAndSettle();
}

Widget _wrap(
    Future<MarkCompleteOutcome> Function(int, int?) onMarkComplete) {
  return MaterialApp(
    home: TaskProgressEntryScreen(
      projectId: '7',
      projectName: 'Villa Kochi',
      onLoadTasks: _oneTask,
      onSaveProgress: _saveProgress,
      onMarkComplete: onMarkComplete,
    ),
  );
}

void main() {
  testWidgets('Idle → Capturing → Queued (happy path)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async {
      // Yield once so the test can observe the Capturing state.
      await Future<void>.delayed(Duration.zero);
      return MarkCompleteOutcome.queued(101, 102);
    }));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn, warnIfMissed: false);
    await tester.pump(); // setState capturing
    expect(find.textContaining('Capturing photo'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.textContaining('Queued'), findsOneWidget);
  });

  testWidgets('Idle → Capturing → ErrorCameraDenied', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async =>
        MarkCompleteOutcome.failed(MarkCompleteError.cameraDenied)));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Camera permission denied'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('Idle → Capturing → ErrorGpsUnavailable surfaces detail message',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async =>
        MarkCompleteOutcome.failed(
            MarkCompleteError.gpsUnavailable, 'Location services disabled.')));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Location services disabled'), findsOneWidget);
  });

  testWidgets('Idle → Capturing → ErrorOutboxFailure', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async =>
        MarkCompleteOutcome.failed(MarkCompleteError.outboxFailure)));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't queue"), findsOneWidget);
  });

  testWidgets('Retry button resets error state back to Idle', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async =>
        MarkCompleteOutcome.failed(MarkCompleteError.cameraDenied)));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Camera permission denied'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Mark complete'), findsOneWidget);
    expect(find.textContaining('Camera permission denied'), findsNothing);
  });

  testWidgets('Wrapper exception (not MarkCompleteOutcome) surfaces ErrorOutboxFailure',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_wrap((taskId, pid) async {
      throw StateError('unexpected');
    }));
    await _openSheetForBeamCasting(tester);

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't queue"), findsOneWidget);
  });
}
