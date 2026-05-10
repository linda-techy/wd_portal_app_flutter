import 'package:admin/features/projects/domain/mark_complete_outcome.dart';
import 'package:admin/features/projects/presentation/screens/task_progress_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<TaskRow>> loadOneTask(String pid, String filter) async {
    return const [
      TaskRow(id: '42', title: 'Beam casting', progressPercent: 50),
    ];
  }

  Future<void> saveProgress(String id, int p, String? n) async {}

  testWidgets(
      'tapping Mark complete invokes onMarkComplete with parsed (taskId, projectId)',
      (tester) async {
    int? receivedTaskId;
    int? receivedProjectId;
    Future<MarkCompleteOutcome> onMarkComplete(int taskId, int? projectId) async {
      receivedTaskId = taskId;
      receivedProjectId = projectId;
      return MarkCompleteOutcome.queued(101, 102);
    }

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(MaterialApp(
      home: TaskProgressEntryScreen(
        projectId: '7',
        projectName: 'Villa Kochi',
        onLoadTasks: loadOneTask,
        onSaveProgress: saveProgress,
        onMarkComplete: onMarkComplete,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beam casting'));
    await tester.pumpAndSettle();

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    expect(btn, findsOneWidget);
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn, warnIfMissed: false);
    // The wrapper does an async chain; pump twice to settle past the
    // first awaited microtask but stop before the post-Queued delay.
    await tester.pump();
    await tester.pump();

    expect(receivedTaskId, 42, reason: 'TaskRow.id "42" parses to int 42');
    expect(receivedProjectId, 7,
        reason: 'projectId resolved from screen.projectId via int.tryParse');
  });

  testWidgets(
      'when TaskRow.id is not parseable as int, callback is NOT invoked and an error is shown',
      (tester) async {
    bool called = false;
    Future<MarkCompleteOutcome> onMarkComplete(int taskId, int? projectId) async {
      called = true;
      return MarkCompleteOutcome.queued(0, 0);
    }

    Future<List<TaskRow>> loadBadIdTask(String pid, String filter) async =>
        const [
          TaskRow(id: 'NOT_AN_INT', title: 'Weird task', progressPercent: 0),
        ];

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(MaterialApp(
      home: TaskProgressEntryScreen(
        projectId: '7',
        projectName: 'Villa Kochi',
        onLoadTasks: loadBadIdTask,
        onSaveProgress: saveProgress,
        onMarkComplete: onMarkComplete,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weird task'));
    await tester.pumpAndSettle();

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn, warnIfMissed: false);
    await tester.pump();
    await tester.pump();

    expect(called, isFalse,
        reason: 'unparseable id short-circuits before the callback');
    expect(find.textContaining("Couldn't queue"), findsOneWidget);
  });
}
