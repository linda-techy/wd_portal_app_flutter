import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Renovation Flow - Change Order Heavy', () {
    testWidgets('should navigate through renovation project modules',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsPM();

      final navHelper = NavigationHelper(tester);

      // Step 1: Projects section loads
      await navHelper.navigateToMenuItem('Projects');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 2: Open first project and navigate to BOQ
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

        // Look for BOQ tab
        final boqTab = find.text('BOQ');
        if (boqTab.evaluate().isNotEmpty) {
          await tester.tap(boqTab.first);
          await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
          expect(find.byType(Scaffold), findsWidgets);
        }
      }

      // Step 3: Site Visits section loads
      await navHelper.navigateToMenuItem('Site Visits');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);

      // Step 4: Reports section loads
      await navHelper.navigateToMenuItem('Reports');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
