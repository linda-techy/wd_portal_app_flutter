// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Web implementation for PDF viewer using iframe
/// Embeds PDF in an iframe using browser's native PDF viewer

Widget buildWebPdfViewer(Uint8List bytes, String filename) {
  // Create a unique view type for this PDF
  final viewType = 'pdf-viewer-${filename.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
  
  // Register the view factory
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      // Create blob URL from PDF bytes
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create iframe element
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      
      return iframe;
    },
  );
  
  // Return HtmlElementView
  return HtmlElementView(
    viewType: viewType,
  );
}
