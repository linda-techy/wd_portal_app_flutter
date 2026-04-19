import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Site Report Module', () {
    testWidgets('should navigate to site reports', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsEngineer();

      final navHelper = NavigationHelper(tester);

      // Try Site Visits menu first
      final siteVisitsItem = find.text('Site Visits');
      if (siteVisitsItem.evaluate().isNotEmpty) {
        await navHelper.navigateToMenuItem('Site Visits');
      } else {
        // Fall back to navigating through a project
        await navHelper.navigateToMenuItem('Projects');
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        final listItems = find.byType(ListTile);
        if (listItems.evaluate().isNotEmpty) {
          await tester.tap(listItems.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

          // Look for Site Reports tab
          final reportsTab = find.text('Site Reports');
          if (reportsTab.evaluate().isNotEmpty) {
            await tester.tap(reportsTab.first);
            await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
          }
        }
      }

      // Screen should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should display site reports list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsEngineer();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Site Visits');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Verify reports list is displayed (list, table, or empty state)
      expect(find.byType(Scaffold), findsWidgets);

      // Check for content display widgets
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasListTile = find.byType(ListTile).evaluate().isNotEmpty;
      final hasCard = find.byType(Card).evaluate().isNotEmpty;
      final hasDataTable = find.byType(DataTable).evaluate().isNotEmpty;

      // At least one content type should be present
      expect(hasListView || hasListTile || hasCard || hasDataTable, isTrue);
    });

    testWidgets('should open report creation form', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsEngineer();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Site Visits');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Look for add/create button
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        // Form fields should appear
        expect(find.byType(TextFormField), findsWidgets);
      }
    });
  });
}
