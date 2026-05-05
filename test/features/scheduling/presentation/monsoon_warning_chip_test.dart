import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';
import 'package:admin/features/scheduling/presentation/widgets/monsoon_warning_chip.dart';

void main() {
  testWidgets('renders amber chip with monsoon icon', (tester) async {
    final warning = MonsoonWarning(
      taskId: 1,
      taskName: 'Slab — Floor 1',
      plannedStart: DateTime(2026, 7, 15),
      plannedEnd: DateTime(2026, 7, 25),
      monsoonStart: DateTime(2026, 6, 1),
      monsoonEnd: DateTime(2026, 9, 30),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MonsoonWarningChip(warning: warning)),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.umbrella), findsOneWidget);
    expect(find.text('Monsoon'), findsOneWidget);
  });

  testWidgets('caller can gate chip on data presence (B10 list pattern)',
      (tester) async {
    // Mirror the Gantt screen's `if (warning != null) MonsoonWarningChip(...)`
    // pattern: rows with a warning render a chip; rows without don't.
    final withWarning = MonsoonWarning(
      taskId: 1,
      taskName: 'A',
      plannedStart: DateTime(2026, 7, 15),
      plannedEnd: DateTime(2026, 7, 25),
      monsoonStart: DateTime(2026, 6, 1),
      monsoonEnd: DateTime(2026, 9, 30),
    );

    Widget rowFor(MonsoonWarning? w) => Row(
          children: [
            const Text('Task'),
            if (w != null) MonsoonWarningChip(warning: w),
          ],
        );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [rowFor(withWarning), rowFor(null)],
        ),
      ),
    ));
    await tester.pump();

    // Only one chip — the row without a warning has none.
    expect(find.byType(MonsoonWarningChip), findsOneWidget);
    expect(find.byIcon(Icons.umbrella), findsOneWidget);
  });

  testWidgets('compact=false shows the date range too', (tester) async {
    final warning = MonsoonWarning(
      taskId: 1,
      taskName: 'Slab',
      plannedStart: DateTime(2026, 7, 15),
      plannedEnd: DateTime(2026, 7, 25),
      monsoonStart: DateTime(2026, 6, 1),
      monsoonEnd: DateTime(2026, 9, 30),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MonsoonWarningChip(warning: warning, compact: false)),
    ));
    await tester.pump();

    expect(find.textContaining('Jun'), findsOneWidget);
    expect(find.textContaining('Sep'), findsOneWidget);
  });
}
