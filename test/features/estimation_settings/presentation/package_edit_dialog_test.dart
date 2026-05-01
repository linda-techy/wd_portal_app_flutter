import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/package_edit_dialog.dart';

void main() {
  testWidgets('create mode: empty marketingName shows validation error', (tester) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await PackageEditDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(find.text('New Estimation Package'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('create mode: valid input returns the form data', (tester) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await PackageEditDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Marketing Name *'), 'Signature');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['marketingName'], 'Signature');
    expect(result!['internalName'], 'STANDARD');
    expect(result!['displayOrder'], 10);
  });

  testWidgets('cancel returns null', (tester) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await PackageEditDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
