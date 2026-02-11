import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile implementation (Android & iOS) for file operations

/// Save file to device and return the file path
Future<String> saveFileToDevice(Uint8List bytes, String filename) async {
  try {
    Directory? directory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory = await getDownloadsDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();
    
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  } catch (e) {
    throw Exception('Failed to save file: $e');
  }
}

/// Download file to device (saves to app directory)
Future<void> downloadFileToDevice(Uint8List bytes, String filename) async {
  try {
    Directory? directory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory = await getDownloadsDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
  } catch (e) {
    throw Exception('Failed to download file: $e');
  }
}

/// Open file with external app
Future<void> openWithExternalApp(String filePath) async {
  try {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Failed to open file: ${result.message}');
    }
  } catch (e) {
    throw Exception('Failed to open file with external app: $e');
  }
}

/// Share file using native share dialog
Future<void> shareFile(String filePath, String filename) async {
  try {
    await Share.shareXFiles([XFile(filePath)], text: filename);
  } catch (e) {
    throw Exception('Failed to share file: $e');
  }
}
