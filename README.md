# wd_portal_app_flutter

A new Flutter project.

## Android build troubleshooting

- **geolocator_android / "substring() on null"**: The root `android/build.gradle` exposes `compileSdkVersion` (and related) on `rootProject` so plugins can read them. If the error persists, run from the terminal: `flutter clean && flutter pub get`, then `flutter build apk`.

- **"The specified initialization script ... does not exist"**: This comes from the Red Hat Java VS Code extension using a missing init script path. You can:
  - Run Android builds from the terminal: `flutter build apk` or `flutter run` (they do not use that init script), or
  - Update the "Extension Pack for Java" / "Language Support for Java" so the extension regenerates its config, or
  - Disable or reinstall the extension if the path stays broken.
