/// Test configuration for portal app integration tests.
///
/// Override API URL via dart-define:
///   flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080
class TestConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator localhost
  );

  /// Test user credentials (seeded in running Portal API — all passwords: Test123$)
  static const String adminEmail = 'adminwalldot@outlook.com';
  static const String adminPassword = 'Test123\$';
  static const String pmEmail = 'pmwalldot@outlook.com';
  static const String pmPassword = 'Test123\$';
  static const String engineerEmail = 'siteengwalldot@outlook.com';
  static const String engineerPassword = 'Test123\$';
  static const String accountsEmail = 'acctasstwalldot@outlook.com';
  static const String accountsPassword = 'Test123\$';

  /// Timeouts for integration tests
  static const Duration pumpSettleDuration = Duration(seconds: 5);
  static const Duration longPumpSettleDuration = Duration(seconds: 10);
}
