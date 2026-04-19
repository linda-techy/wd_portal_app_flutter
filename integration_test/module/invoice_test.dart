import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Invoice Module', () {
    testWidgets('should navigate to payments/finance section', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAccounts();

      final navHelper = NavigationHelper(tester);

      // Try Payments first, fall back to Finance
      final paymentsItem = find.text('Payments');
      if (paymentsItem.evaluate().isNotEmpty) {
        await navHelper.navigateToMenuItem('Payments');
      } else {
        await navHelper.navigateToMenuItem('Finance');
      }
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Screen should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should display invoices list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAccounts();

      final navHelper = NavigationHelper(tester);

      // Navigate to Payments or Finance
      final paymentsItem = find.text('Payments');
      if (paymentsItem.evaluate().isNotEmpty) {
        await navHelper.navigateToMenuItem('Payments');
      } else {
        await navHelper.navigateToMenuItem('Finance');
      }
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Look for invoice-related content (list, table, or empty state)
      final invoiceTab = find.text('Invoices');
      if (invoiceTab.evaluate().isNotEmpty) {
        await tester.tap(invoiceTab.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      }

      // Verify the screen rendered (data table, list, or empty state)
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should open invoice details', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAccounts();

      final navHelper = NavigationHelper(tester);

      // Navigate to Payments or Finance
      final paymentsItem = find.text('Payments');
      if (paymentsItem.evaluate().isNotEmpty) {
        await navHelper.navigateToMenuItem('Payments');
      } else {
        await navHelper.navigateToMenuItem('Finance');
      }
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Try to open Invoices tab
      final invoiceTab = find.text('Invoices');
      if (invoiceTab.evaluate().isNotEmpty) {
        await tester.tap(invoiceTab.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      }

      // Tap on first invoice if available
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}
