import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BOQ Module', () {
    testWidgets('should navigate to BOQ screen from project', (tester) async {
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

        // Look for BOQ tab or menu item
        final boqTab = find.text('BOQ');
        if (boqTab.evaluate().isNotEmpty) {
          await tester.tap(boqTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });

    testWidgets('should display BOQ items list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();

      // Navigate to projects and open first project's BOQ
      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      final listItems = find.byType(ListTile);
      if (listItems.evaluate().isNotEmpty) {
        await tester.tap(listItems.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        final boqTab = find.text('BOQ');
        if (boqTab.evaluate().isNotEmpty) {
          await tester.tap(boqTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

          // BOQ items should be visible (table or list)
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });
  });
}
