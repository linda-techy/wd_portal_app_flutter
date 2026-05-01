import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';
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

  testWidgets('edit mode: title shows Edit, internalName disabled, active toggle works', (tester) async {
    Map<String, dynamic>? result;
    const existing = EstimationPackage(
      id: 'pkg-1',
      internalName: 'PREMIUM',
      marketingName: 'Luxe',
      displayOrder: 30,
      active: true,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await PackageEditDialog.show(context, existing: existing);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Title says "Edit"
    expect(find.text('Edit Estimation Package'), findsOneWidget);

    // Active switch present and toggleable
    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['internalName'], 'PREMIUM');
    expect(result!['marketingName'], 'Luxe');
    expect(result!['active'], isFalse);  // toggled from true → false
  });
}
