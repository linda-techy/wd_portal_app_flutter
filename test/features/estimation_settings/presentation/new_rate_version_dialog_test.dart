import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/new_rate_version_dialog.dart';

void main() {
  Widget wrap(void Function(Map<String, dynamic>?) onResult) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await NewRateVersionDialog.show(context);
                onResult(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('empty rates show validation errors and dialog stays open', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(3));
    expect(find.text('New Rate Version'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('valid input returns the form data with numeric rates', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Material rate (₹/sqft) *'), '1600');
    await tester.enterText(find.widgetWithText(TextFormField, 'Labour rate (₹/sqft) *'), '600');
    await tester.enterText(find.widgetWithText(TextFormField, 'Overhead rate (₹/sqft) *'), '320');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['materialRate'], 1600);
    expect(result!['labourRate'], 600);
    expect(result!['overheadRate'], 320);
    expect(result!.containsKey('effectiveFrom'), isFalse);
  });

  testWidgets('cancel returns null without validating', (tester) async {
    Map<String, dynamic>? result = <String, dynamic>{'sentinel': true};
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Required'), findsNothing,
        reason: 'Cancel must not trigger form validation');
  });
}
