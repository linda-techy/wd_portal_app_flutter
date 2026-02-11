import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Stub implementation for web PDF viewer
/// This is used on non-web platforms

Widget buildWebPdfViewer(Uint8List bytes, String filename) {
  throw UnsupportedError('Web PDF viewer is only supported on web platform');
}
