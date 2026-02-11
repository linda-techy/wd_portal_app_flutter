import 'dart:typed_data';

/// Stub implementation - should never be called
/// Real implementations are in file_operations_mobile.dart and file_operations_web.dart

Future<String> saveFileToDevice(Uint8List bytes, String filename) async {
  throw UnsupportedError('saveFileToDevice is not supported on this platform');
}

Future<void> downloadFileToDevice(Uint8List bytes, String filename) async {
  throw UnsupportedError('downloadFileToDevice is not supported on this platform');
}

Future<void> openWithExternalApp(String filePath) async {
  throw UnsupportedError('openWithExternalApp is not supported on this platform');
}

Future<void> shareFile(String filePath, String filename) async {
  throw UnsupportedError('shareFile is not supported on this platform');
}
