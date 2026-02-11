// Web-specific implementation for file downloads
// This file is only imported on web platform

import 'dart:typed_data';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific file download implementation
class FileDownloadHelperWeb {
  /// Download file on web using browser download API
  static Future<void> downloadFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      // Convert bytes to base64
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:$mimeType;base64,$base64String';

      // Create anchor element and trigger download
      final anchor = html.AnchorElement(href: dataUrl)
        ..download = fileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      // For large files, use blob URL instead
      try {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } catch (e2) {
        throw Exception('Failed to download file on web: $e2');
      }
    }
  }
}
