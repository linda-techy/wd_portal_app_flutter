// Stub implementation for non-web platforms
// This file is imported when dart.library.io is available (non-web)

import 'dart:typed_data';

/// Stub class for web file download helper (not used on non-web platforms)
class FileDownloadHelperWeb {
  /// Stub method - never called on non-web platforms
  static Future<void> downloadFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    throw UnimplementedError(
        'This should never be called on non-web platforms');
  }
}
