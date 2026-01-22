import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

// Platform-specific imports
import 'dart:io' show File;

// Web-specific implementation (only imported on web)
// Import web version when dart.library.html is available, stub otherwise
import 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_stub.dart' as web_helper;

/// Cross-platform file download and share utility
/// Handles file downloads on web, Android, iOS, and Windows
class FileDownloadHelper {
  /// Download and share a file across all platforms
  ///
  /// On web: Triggers browser download using data URL or blob URL
  /// On mobile/desktop: Saves to temp directory and shares via system share dialog
  ///
  /// [bytes] - File content as bytes
  /// [fileName] - Name of the file (e.g., "document.pdf")
  /// [mimeType] - MIME type (e.g., "application/pdf", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  /// [shareText] - Optional text to include when sharing
  static Future<void> downloadAndShareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? shareText,
  }) async {
    if (kIsWeb) {
      // Web platform: Use browser download API
      await web_helper.FileDownloadHelperWeb.downloadFile(
          bytes, fileName, mimeType);
    } else {
      // Mobile/Desktop platforms: Save to temp directory and share
      await _downloadOnMobile(bytes, fileName, shareText);
    }
  }

  /// Download and share file on mobile/desktop platforms
  static Future<void> _downloadOnMobile(
    Uint8List bytes,
    String fileName,
    String? shareText,
  ) async {
    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      // Write bytes to file
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}
