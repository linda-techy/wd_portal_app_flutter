import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Residential Flow', () {
    testWidgets('should complete residential project smoke test',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      // Step 1: Login as PM
      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();
      await loginHelper.verifyDashboardLoaded();

      final navHelper = NavigationHelper(tester);

      // Step 2: Navigate to Projects and verify list loads
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Verify project list has content (list, table, or empty state)
      final hasProjectContent =
          find.byType(ListView).evaluate().isNotEmpty ||
              find.byType(ListTile).evaluate().isNotEmpty ||
              find.byType(Card).evaluate().isNotEmpty ||
              find.byType(DataTable).evaluate().isNotEmpty;
      expect(hasProjectContent, isTrue);

      // Step 3: Navigate to Payments and verify section loads
      await navHelper.navigateToMenuItem('Payments');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Verify payments section rendered
      final hasPaymentContent =
          find.byType(ListView).evaluate().isNotEmpty ||
              find.byType(ListTile).evaluate().isNotEmpty ||
              find.byType(Card).evaluate().isNotEmpty ||
              find.byType(DataTable).evaluate().isNotEmpty;
      expect(hasPaymentContent, isTrue);

      // Step 4: Navigate to Labour and verify section loads
      await navHelper.navigateToMenuItem('Labour');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Verify labour section rendered
      final hasLabourContent =
          find.byType(ListView).evaluate().isNotEmpty ||
              find.byType(ListTile).evaluate().isNotEmpty ||
              find.byType(Card).evaluate().isNotEmpty ||
              find.byType(DataTable).evaluate().isNotEmpty;
      expect(hasLabourContent, isTrue);
    });
  });
}
