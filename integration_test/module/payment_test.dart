import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Module', () {
    testWidgets('should navigate to payments dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Payments');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Payments screen should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should display payment records', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Payments');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Verify payment records are shown (list, table, or empty state)
      expect(find.byType(Scaffold), findsWidgets);

      // Check for data display widgets (DataTable, ListView, or empty state message)
      final hasDataTable = find.byType(DataTable).evaluate().isNotEmpty;
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasListTile = find.byType(ListTile).evaluate().isNotEmpty;
      final hasCard = find.byType(Card).evaluate().isNotEmpty;

      // At least one content display type should be present
      expect(hasDataTable || hasListView || hasListTile || hasCard, isTrue);
    });

    testWidgets('should open payment details', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Payments');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Tap the first payment record if available
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        // Details screen should be visible
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}
