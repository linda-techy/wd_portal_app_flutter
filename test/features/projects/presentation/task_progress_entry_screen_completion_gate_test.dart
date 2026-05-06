import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/features/projects/presentation/screens/task_progress_entry_screen.dart';

void main() {
  Future<List<TaskRow>> loadOneTask(String pid, String filter) async {
    return const [
      TaskRow(id: '42', title: 'Beam casting', progressPercent: 50)
    ];
  }

  Future<void> saveProgress(String id, int p, String? n) async {}

  testWidgets('mark-complete button disabled when no geotagged COMPLETION photo',
      (tester) async {
    bool checkCalled = false;
    bool markCalled = false;

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(MaterialApp(
      home: TaskProgressEntryScreen(
        projectId: '7',
        projectName: 'Villa Kochi',
        onLoadTasks: loadOneTask,
        onSaveProgress: saveProgress,
        onCheckCompletionPhoto: (id) async {
          checkCalled = true;
          return false; // No photo yet.
        },
        onMarkComplete: (id) async {
          markCalled = true;
          return 'COMPLETED';
        },
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Beam casting'));
    await tester.pump();
    await tester.pump();

    expect(checkCalled, isTrue);
    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    expect(btn, findsOneWidget);
    expect(tester.widget<FilledButton>(btn).onPressed, isNull,
        reason: 'Button must be disabled until photo evidence exists');
    expect(markCalled, isFalse);
  });

  testWidgets('mark-complete button enabled when photo present, fires callback',
      (tester) async {
    bool markCalled = false;

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(MaterialApp(
      home: TaskProgressEntryScreen(
        projectId: '7',
        projectName: 'Villa Kochi',
        onLoadTasks: loadOneTask,
        onSaveProgress: saveProgress,
        onCheckCompletionPhoto: (id) async => true,
        onMarkComplete: (id) async {
          markCalled = true;
          return 'PENDING_PM_APPROVAL';
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beam casting'));
    await tester.pumpAndSettle();

    final btn = find.widgetWithText(FilledButton, 'Mark complete');
    expect(tester.widget<FilledButton>(btn).onPressed, isNotNull);

    // Scroll the button into view if it's below the fold of the bottom
    // sheet's SingleChildScrollView (the test viewport is 900x1200 and
    // the sheet stacks the bottom-sheet form + Mark-complete row).
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(markCalled, isTrue);
    expect(find.textContaining('Pending PM approval'), findsOneWidget);
  });
}
