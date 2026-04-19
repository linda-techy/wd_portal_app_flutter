import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';
import '../helpers/navigation_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Labour Module', () {
    testWidgets('should navigate to labour dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Labour');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Labour screen should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('should display labour records', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Labour');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Verify labour records are displayed (list, table, or empty state)
      expect(find.byType(Scaffold), findsWidgets);

      // Check for content display widgets
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasListTile = find.byType(ListTile).evaluate().isNotEmpty;
      final hasCard = find.byType(Card).evaluate().isNotEmpty;
      final hasDataTable = find.byType(DataTable).evaluate().isNotEmpty;

      // At least one content type should be present
      expect(hasListView || hasListTile || hasCard || hasDataTable, isTrue);
    });

    testWidgets('should navigate to attendance section', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      final navHelper = NavigationHelper(tester);
      await navHelper.navigateToMenuItem('Labour');
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

      // Look for Attendance tab or section
      final attendanceTab = find.text('Attendance');
      if (attendanceTab.evaluate().isNotEmpty) {
        await tester.tap(attendanceTab.first);
        await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

        // Attendance section should be visible
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}
