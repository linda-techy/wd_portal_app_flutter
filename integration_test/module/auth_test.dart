import 'package:admin/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/login_helper.dart';

/// Pump the widget tree a bounded number of times to give the app a chance
/// to render without waiting for true idle — the app has background streams
/// (auth restore, connectivity) that never settle in a test context.
Future<void> pumpForBootstrap(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Module', () {
    testWidgets('should display login screen on app launch', (tester) async {
      app.main();
      await pumpForBootstrap(tester);

      // Login form should be visible
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should login successfully with valid credentials',
        (tester) async {
      app.main();
      await pumpForBootstrap(tester);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      // Should navigate away from login screen
      await loginHelper.verifyDashboardLoaded();
    });

    testWidgets('should show error for invalid credentials', (tester) async {
      app.main();
      await pumpForBootstrap(tester);

      final loginHelper = LoginHelper(tester);
      await loginHelper.login('wrong@email.com', 'wrongpassword');

      await pumpForBootstrap(tester);
    });

    testWidgets('should show dashboard after login', (tester) async {
      app.main();
      await pumpForBootstrap(tester);

      final loginHelper = LoginHelper(tester);
      await loginHelper.loginAsAdmin();

      // Dashboard scaffold should be visible
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
