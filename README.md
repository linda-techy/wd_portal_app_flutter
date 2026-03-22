# Portal App (Flutter)

Internal portal application for staff and admins to manage CRM, projects, tasks, and construction operations.

## Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / Xcode (for mobile development)
- Access to the Portal API

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API Endpoint

Edit `lib/config/app_config.dart`:

```dart
// Local development
static const String localApiUrl = 'http://localhost:8080';

// Production
static const String productionApiUrl = 'https://api.walldotbuilders.com';
```

### 3. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release
```

## Security Fixes Applied

### Critical Issues Fixed

✅ **Redacted Token Logging** - Authentication tokens are now redacted in logs
  - Changed from logging token substring to `[REDACTED]`
  - Prevents token exposure in debug logs

✅ **Improved Error Handling** - Better error logging throughout the app

### Code Quality Improvements

✅ **Consistent Storage Access** - Using `StorageService` singleton pattern
✅ **Better Debug Logging** - Excessive debug logs cleaned up

## Security Best Practices

### Do NOT Log Sensitive Data

Never log:
- Authentication tokens (even partial)
- Passwords or password hints
- Personal information
- API keys or secrets

### Token Handling

When debugging authentication issues, log status only:

```dart
// Good
debugPrint('Token: [REDACTED]');

// Bad
debugPrint('Token: ${token.substring(0, 20)}...');
```

### Secure Storage

Use `StorageService` singleton for consistent secure storage access:

```dart
final storage = StorageService();
final token = await storage.read('access_token');
```

## Features

- **CRM Dashboard** - Lead management and analytics
- **Project Management** - Track construction projects
- **Task Management** - Assign and track tasks
- **Site Reports** - Construction site reporting
- **Vendor Management** - Manage partnerships and vendors
- **Document Management** - Upload and manage project documents
- **Gallery** - Project photo galleries
- **BOQ Management** - Bill of Quantities

## Development

### Debug Mode

Keep debug output minimal and safe:

```dart
if (kDebugMode) {
  debugPrint('Loading file: ${filename}');
  // Never log tokens, passwords, or sensitive data
}
```

### Code Style

- Use proper error handling (no empty catch blocks)
- Add `mounted` checks before `setState()` in async operations
- Use consistent storage patterns
- Follow Flutter best practices
- Consolidate configuration classes

## Configuration Issues Fixed

### Duplicate Configuration Classes

The app previously had two configuration classes:
- `AppConfig` in `lib/config/app_config.dart`
- `ApiConfig` in `lib/constants.dart`

Consider consolidating these for better maintainability.

### Storage Service Usage

Use `StorageService` singleton consistently instead of creating new `FlutterSecureStorage()` instances.

## Building for Production

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Before Release

- [ ] Verify all tokens are redacted in logs
- [ ] Test authentication flow thoroughly
- [ ] Verify API endpoint configuration
- [ ] Test on multiple devices/screen sizes
- [ ] Run `flutter analyze` and fix warnings
- [ ] Test offline behavior
- [ ] Verify file upload/download functionality

## Troubleshooting

### Authentication Issues

If staff can't log in:
1. Verify Portal API endpoint is correct
2. Check token storage
3. Ensure API is running and healthy
4. Verify user has correct role/permissions

### File Viewer Issues

If documents won't load:
1. Check storage path configuration
2. Verify token is being sent correctly
3. Ensure API storage endpoints are accessible
4. Check file permissions on storage directory

### Empty Catch Blocks

If you encounter silent failures, check for empty catch blocks that were identified but not all fixed. Add proper error logging:

```dart
try {
  // operation
} catch (e) {
  debugPrint('Operation failed: $e');
  // Handle error appropriately
}
```

## Related Projects

- **Portal API**: Backend API for this app
- **Customer App**: Customer-facing application

## Security

For security guidelines and incident response, see the Portal API's SECURITY.md file.
