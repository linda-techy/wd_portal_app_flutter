import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Commercial Flow - Multi-Vendor Build', () {
    testWidgets('should navigate through commercial project modules',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);

      // Step 1: Projects section loads
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 2: Procurement section loads
      await navHelper.navigateToMenuItem('Procurement');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 3: Labour section loads
      await navHelper.navigateToMenuItem('Labour');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 4: Inventory section loads
      await navHelper.navigateToMenuItem('Inventory');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 5: Finance section loads
      await navHelper.navigateToMenuItem('Finance');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 6: Payments section loads
      await navHelper.navigateToMenuItem('Payments');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
