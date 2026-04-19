/// Test configuration for portal app integration tests.
///
/// Override API URL via dart-define:
///   flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080
class TestConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator localhost
  );

  /// Test user credentials (must match TestDataSeeder in portal API)
  static const String adminEmail = 'admin@test.com';
  static const String adminPassword = 'password123';
  static const String pmEmail = 'pm@test.com';
  static const String pmPassword = 'password123';
  static const String engineerEmail = 'engineer@test.com';
  static const String engineerPassword = 'password123';
  static const String accountsEmail = 'accounts@test.com';
  static const String accountsPassword = 'password123';

  /// Timeouts for integration tests
  static const Duration pumpSettleDuration = Duration(seconds: 5);
  static const Duration longPumpSettleDuration = Duration(seconds: 10);
}
