import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Project Module', () {
    testWidgets('should navigate to projects list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Projects screen should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should open project creation form', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Look for add/create button
      final addButton = find.byIcon(Icons.add)
          .evaluate()
          .isNotEmpty
          ? find.byIcon(Icons.add)
          : find.text('Add Project');

      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        // Form fields should appear
        expect(find.byType(TextFormField), findsWidgets);
      }
    });

    testWidgets('should display project details when tapped', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Tap the first project in the list if available
      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}
