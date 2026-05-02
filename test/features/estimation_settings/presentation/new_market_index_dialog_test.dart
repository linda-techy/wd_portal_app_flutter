import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/new_market_index_dialog.dart';

void main() {
  Widget wrap(void Function(Map<String, dynamic>?) onResult) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                onResult(await NewMarketIndexDialog.show(context));
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('empty fields show validation errors and dialog stays open', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publish'));
    await tester.pump();

    // 7 rate fields + 7 weight fields = 14 "Required" errors
    expect(find.text('Required'), findsNWidgets(14));
    expect(find.text('New Market Index Snapshot'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('valid input returns the form data with rates + weights map', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Fill rates
    final rateValues = {
      'steel': '62.5', 'cement': '410', 'sand': '5800', 'aggregate': '1850',
      'tiles': '38', 'electrical': '92', 'paints': '285',
    };
    for (final entry in rateValues.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, '${entry.key} rate *'),
        entry.value,
      );
    }
    // Fill weights (sum to 1.00)
    final weightValues = {
      'steel': '0.30', 'cement': '0.20', 'sand': '0.12', 'aggregate': '0.08',
      'tiles': '0.12', 'electrical': '0.10', 'paints': '0.08',
    };
    for (final entry in weightValues.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, '${entry.key} weight *'),
        entry.value,
      );
    }

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['rates'], isA<Map>());
    expect(result!['rates']['steel'], 62.5);
    expect(result!['rates']['paints'], 285.0);
    expect(result!['weights'], isA<Map>());
    expect(result!['weights']['steel'], 0.30);
    expect(result!.containsKey('snapshotDate'), isFalse);
  });
}
