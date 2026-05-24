// Regression test for the "BoQ edit modal not coming" bug.
//
// Root cause (captured from the running app's browser console):
//
//   Flutter Error: RenderFlex children have non-zero flex but incoming width
//   constraints are unbounded.
//   The affected RenderFlex creator:
//     Row ← Align ← ConstrainedBox ← Semantics ← DropdownMenuItem<int>
//          ← ... ← IndexedStack ← ...
//
// BoqScreen._buildHierarchicalCategoryItems() builds each category as a
// DropdownMenuItem whose child is a Row containing an Expanded label. A
// DropdownButton lays its items out in an IndexedStack to measure the button,
// and only gives them a *bounded* width when `isExpanded: true`. The Add dialog
// set `isExpanded: true`; the Edit dialog did not, so the Expanded inside the
// item Row was measured at unbounded width and threw during layout — the
// AlertDialog content subtree failed to build and the dialog rendered as a bare
// backdrop ("edit modal not coming").
//
// These tests pin the behaviour: the exact item pattern crashes WITHOUT
// `isExpanded` and renders cleanly WITH it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors BoqScreen._buildHierarchicalCategoryItems(): a category row with an
/// Expanded label (the shape that trips the unbounded-flex assertion).
List<DropdownMenuItem<int>> hierarchicalCategoryItems() => [
      for (final c in const [
        (1, 'Foundation Works'),
        (2, 'Superstructure & RCC'),
        (3, 'Plastering'),
      ])
        DropdownMenuItem<int>(
          value: c.$1,
          child: Row(
            children: [
              const Icon(Icons.folder, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.$2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
    ];

/// Builds the Edit-dialog category dropdown the same way the screen does,
/// toggling only the property under test.
Widget buildCategoryDialog({required bool isExpanded}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: AlertDialog(
            title: const Text('Edit BoQ Item'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int?>(
                      value: 1, // an item present in the list (like an edited item)
                      isExpanded: isExpanded,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('No Category')),
                        ...hierarchicalCategoryItems(),
                      ],
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'BUG: category dropdown with Expanded items throws unbounded-flex without isExpanded',
    (tester) async {
      // The unbounded-flex failure cascades into many downstream layout/hit-test
      // errors (≈40, just like the running app's console). Collect them all so
      // we can assert on the root "non-zero flex" message rather than the
      // framework's "Multiple exceptions" aggregate.
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details.toString());
      try {
        await tester.pumpWidget(buildCategoryDialog(isExpanded: false));
      } finally {
        FlutterError.onError = previous;
      }

      expect(errors, isNotEmpty,
          reason: 'The pre-fix Edit dialog should crash during layout.');
      expect(
        errors.any((e) => e.contains('non-zero flex')),
        isTrue,
        reason: 'Root cause must be the unbounded-width RenderFlex assertion.',
      );
    },
  );

  testWidgets(
    'FIX: isExpanded: true lets the same items lay out cleanly (modal renders)',
    (tester) async {
      await tester.pumpWidget(buildCategoryDialog(isExpanded: true));

      expect(tester.takeException(), isNull,
          reason: 'With isExpanded:true the dialog must build without error.');
      // The dialog actually rendered: title + dropdown are present.
      expect(find.text('Edit BoQ Item'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);
    },
  );
}
