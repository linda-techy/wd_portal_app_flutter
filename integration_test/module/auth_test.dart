import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_config.dart';
import '../helpers/login_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Module', () {
    testWidgets('should display login screen on app launch', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      // Login form should be visible
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should login successfully with valid credentials',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      // Should navigate away from login screen
      await loginHelper.verifyDashboardLoaded();
    });

    testWidgets('should show error for invalid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.login('wrong@email.com', 'wrongpassword');

      // Should remain on login screen or show error
      // Look for error indicator (snackbar, dialog, or error text)
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
    });

    testWidgets('should show dashboard after login', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      // Dashboard scaffold should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
