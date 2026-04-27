// Widget tests for the QuotationRowActions popup-menu widget.
//
// Asserts:
//   1. Status-gated visibility — DRAFT vs SENT show different action sets.
//   2. Each action invokes its corresponding callback exactly once.
//
// QuotationRowActions has zero external dependencies aside from the
// LeadQuotation model, so no mocks are needed.

import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/screens/quotations/widgets/quotation_row_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LeadQuotation _quotation({String status = 'DRAFT'}) {
  return LeadQuotation(
    id: 1,
    leadId: 99,
    title: 'Sample quotation',
    status: status,
  );
}

/// Pump the widget wrapped in MaterialApp so PopupMenuButton + theming work.
Future<void> _pumpWidget(
  WidgetTester tester, {
  required LeadQuotation quotation,
  VoidCallback? onView,
  VoidCallback? onEdit,
  VoidCallback? onAddFromCatalog,
  VoidCallback? onSend,
  VoidCallback? onAccept,
  VoidCallback? onReject,
  VoidCallback? onPreviewPdf,
  VoidCallback? onDownloadPdf,
  VoidCallback? onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: QuotationRowActions(
            quotation: quotation,
            onView: onView,
            onEdit: onEdit,
            onAddFromCatalog: onAddFromCatalog,
            onSend: onSend,
            onAccept: onAccept,
            onReject: onReject,
            onPreviewPdf: onPreviewPdf,
            onDownloadPdf: onDownloadPdf,
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  group('QuotationRowActions — status-gated visibility', () {
    testWidgets(
      'DRAFT shows Edit / Add from catalog / Send / Delete and hides Accept/Reject',
      (tester) async {
        await _pumpWidget(
          tester,
          quotation: _quotation(status: 'DRAFT'),
          onView: () {},
          onEdit: () {},
          onAddFromCatalog: () {},
          onSend: () {},
          onAccept: () {},
          onReject: () {},
          onPreviewPdf: () {},
          onDownloadPdf: () {},
          onDelete: () {},
        );
        await _openMenu(tester);

        // Visible for DRAFT.
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Add from catalog'), findsOneWidget);
        expect(find.text('Send'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Hidden for DRAFT.
        expect(find.text('Accept'), findsNothing);
        expect(find.text('Reject'), findsNothing);

        // Always visible regardless of status.
        expect(find.text('View'), findsOneWidget);
        expect(find.text('PDF Preview'), findsOneWidget);
        expect(find.text('PDF Download'), findsOneWidget);
      },
    );

    testWidgets(
      'SENT shows Accept / Reject / PDF Preview / Download and hides Edit/Send/Delete',
      (tester) async {
        await _pumpWidget(
          tester,
          quotation: _quotation(status: 'SENT'),
          onView: () {},
          onEdit: () {},
          onAddFromCatalog: () {},
          onSend: () {},
          onAccept: () {},
          onReject: () {},
          onPreviewPdf: () {},
          onDownloadPdf: () {},
          onDelete: () {},
        );
        await _openMenu(tester);

        // Visible for SENT.
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('PDF Preview'), findsOneWidget);
        expect(find.text('PDF Download'), findsOneWidget);
        expect(find.text('View'), findsOneWidget);

        // Hidden for SENT.
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Add from catalog'), findsNothing);
        expect(find.text('Send'), findsNothing);
        expect(find.text('Delete'), findsNothing);
      },
    );

    testWidgets('null callbacks hide the corresponding menu items', (tester) async {
      // Provide ONLY view + preview; everything else is null.
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onView: () {},
        onPreviewPdf: () {},
      );
      await _openMenu(tester);

      expect(find.text('View'), findsOneWidget);
      expect(find.text('PDF Preview'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Add from catalog'), findsNothing);
      expect(find.text('Send'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('PDF Download'), findsNothing);
    });
  });

  group('QuotationRowActions — callback dispatch', () {
    testWidgets('tapping View invokes onView once', (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onView: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Edit invokes onEdit once (DRAFT only)', (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onEdit: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Add from catalog invokes onAddFromCatalog once',
        (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onAddFromCatalog: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Add from catalog'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Send invokes onSend once (DRAFT only)', (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onSend: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Accept invokes onAccept once (SENT only)',
        (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'SENT'),
        onAccept: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Reject invokes onReject once (SENT only)',
        (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'SENT'),
        onReject: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping PDF Preview invokes onPreviewPdf once', (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'SENT'),
        onPreviewPdf: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('PDF Preview'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping PDF Download invokes onDownloadPdf once',
        (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'SENT'),
        onDownloadPdf: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('PDF Download'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });

    testWidgets('tapping Delete invokes onDelete once (DRAFT only)',
        (tester) async {
      var count = 0;
      await _pumpWidget(
        tester,
        quotation: _quotation(status: 'DRAFT'),
        onDelete: () => count++,
      );
      await _openMenu(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(count, 1);
    });
  });
}
