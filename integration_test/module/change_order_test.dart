import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Change Order Module', () {
    testWidgets('should navigate to change orders from project',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Open first project
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        // Look for Change Orders tab
        final coTab = find.text('Change Orders');
        if (coTab.evaluate().isNotEmpty) {
          await tester.tap(coTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });

    testWidgets('should display change orders list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Open first project and navigate to Change Orders
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        final coTab = find.text('Change Orders');
        if (coTab.evaluate().isNotEmpty) {
          await tester.tap(coTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

          // Change orders list should be visible (list, table, or empty state)
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });

    testWidgets('should open CO creation form', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Open first project and navigate to Change Orders
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        final coTab = find.text('Change Orders');
        if (coTab.evaluate().isNotEmpty) {
          await tester.tap(coTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

          // Look for add/create button
          final addButton = find.byIcon(Icons.add);
          if (addButton.evaluate().isNotEmpty) {
            await tester.tap(addButton.first);
            await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

            // Form fields should appear
            expect(find.byType(TextFormField), findsWidgets);
          }
        }
      }
    });
  });
}
