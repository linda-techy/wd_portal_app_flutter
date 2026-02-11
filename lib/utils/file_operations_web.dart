// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation for file operations

/// Save file to browser (triggers download)
/// Returns a fake path since web doesn't have file system
Future<String> saveFileToDevice(Uint8List bytes, String filename) async {
  try {
    _triggerBrowserDownload(bytes, filename);
    return 'web://$filename'; // Fake path for web
  } catch (e) {
    throw Exception('Failed to save file: $e');
  }
}

/// Download file to browser
Future<void> downloadFileToDevice(Uint8List bytes, String filename) async {
  try {
    _triggerBrowserDownload(bytes, filename);
  } catch (e) {
    throw Exception('Failed to download file: $e');
  }
}

/// Open with external app (not supported on web, triggers download instead)
Future<void> openWithExternalApp(String filePath) async {
  throw UnsupportedError('Opening with external app is not supported on web');
}

/// Share file (not supported on web, triggers download instead)
Future<void> shareFile(String filePath, String filename) async {
  throw UnsupportedError('Sharing is not supported on web. Use download instead.');
}

/// Helper function to trigger browser download
void _triggerBrowserDownload(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
