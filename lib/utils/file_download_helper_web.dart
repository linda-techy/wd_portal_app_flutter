// Web-specific implementation for file downloads
// This file is only imported on web platform

import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific file download implementation.
///
/// Uses a Blob URL rather than a `data:` URL because base64-encoding multi-MB
/// PDFs synchronously on the main thread can stall the UI long enough that
/// users perceive the surrounding loader as "stuck".
class FileDownloadHelperWeb {
  static Future<void> downloadFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final blob = html.Blob(<dynamic>[bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    try {
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  }
}
