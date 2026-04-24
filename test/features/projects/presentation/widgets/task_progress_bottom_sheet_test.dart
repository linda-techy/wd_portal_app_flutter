import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/features/projects/presentation/widgets/task_progress_bottom_sheet.dart';

void main() {
  testWidgets('save invokes callback with rounded progress and note',
      (tester) async {
    int? saved;
    String? savedNote;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskProgressBottomSheet(
          taskTitle: 'X',
          initialProgress: 50,
          onSave: (p, n) async {
            saved = p;
            savedNote = n;
          },
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'note text');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, 50);
    expect(savedNote, 'note text');
  });

  testWidgets('mark complete sets to 100 and save fires with 100',
      (tester) async {
    int? saved;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskProgressBottomSheet(
          taskTitle: 'X',
          initialProgress: 30,
          onSave: (p, n) async {
            saved = p;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Mark complete'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, 100);
  });

  testWidgets('slider divisions config snaps to 5%', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskProgressBottomSheet(
          taskTitle: 'X',
          initialProgress: 0,
          onSave: (p, n) async {},
        ),
      ),
    ));

    final slider = tester.widget<Slider>(find.byType(Slider));
    // 100 / 5 = 20 divisions
    expect(slider.divisions, 20);
    expect(slider.min, 0);
    expect(slider.max, 100);
  });
}
