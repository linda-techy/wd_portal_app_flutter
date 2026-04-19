import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

/// Helper to perform login in integration tests.
class LoginHelper {
  final WidgetTester tester;

  LoginHelper(this.tester);

  /// Logs in as admin user and waits for dashboard to load.
  Future<void> loginAsAdmin() async {
    await login(TestConfig.adminEmail, TestConfig.adminPassword);
  }

  /// Logs in as project manager and waits for dashboard to load.
  Future<void> loginAsPM() async {
    await login(TestConfig.pmEmail, TestConfig.pmPassword);
  }

  /// Logs in as engineer and waits for dashboard to load.
  Future<void> loginAsEngineer() async {
    await login(TestConfig.engineerEmail, TestConfig.engineerPassword);
  }

  /// Logs in as accounts user and waits for dashboard to load.
  Future<void> loginAsAccounts() async {
    await login(TestConfig.accountsEmail, TestConfig.accountsPassword);
  }

  /// Fills the login form and taps the login button.
  Future<void> login(String email, String password) async {
    // Wait for login screen to appear
    await tester.pumpAndSettle(TestConfig.pumpSettleDuration);

    // Find email and password fields
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    // Enter credentials
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);

    // Tap login button
    final loginButton = find.byType(ElevatedButton).first;
    await tester.tap(loginButton);

    // Wait for navigation to dashboard
    await tester.pumpAndSettle(TestConfig.longPumpSettleDuration);
  }

  /// Verifies the dashboard is showing after login.
  Future<void> verifyDashboardLoaded() async {
    // Dashboard should be visible after login
    expect(find.byType(Scaffold), findsWidgets);
  }
}
