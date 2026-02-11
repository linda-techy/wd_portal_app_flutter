import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
enum FileType {
  pdf,
  image,
  word,
  excel,
  csv,
  powerpoint,
  text,
  video,
  audio,
  other
}

class FileViewerService {
  static final Dio _dio = Dio();

  /// Detect file type from filename or MIME type
  static FileType detectFileType(String filename, {String? mimeType}) {
    final extension = filename.toLowerCase().split('.').last;
    
    // Check by extension first
    if (_pdfExtensions.contains(extension)) return FileType.pdf;
    if (_imageExtensions.contains(extension)) return FileType.image;
    if (_wordExtensions.contains(extension)) return FileType.word;
    if (_excelExtensions.contains(extension)) return FileType.excel;
    if (_csvExtensions.contains(extension)) return FileType.csv;
    if (_powerpointExtensions.contains(extension)) return FileType.powerpoint;
    if (_textExtensions.contains(extension)) return FileType.text;
    if (_videoExtensions.contains(extension)) return FileType.video;
    if (_audioExtensions.contains(extension)) return FileType.audio;

    // Fallback to MIME type detection
    if (mimeType != null) {
      if (mimeType.contains('pdf')) return FileType.pdf;
      if (mimeType.contains('image')) return FileType.image;
      if (mimeType.contains('word') || mimeType.contains('msword') || 
          mimeType.contains('document')) return FileType.word;
      if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return FileType.excel;
      if (mimeType.contains('csv') || mimeType.contains('comma-separated')) return FileType.csv;
      if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return FileType.powerpoint;
      if (mimeType.contains('text')) return FileType.text;
      if (mimeType.contains('video')) return FileType.video;
      if (mimeType.contains('audio')) return FileType.audio;
    }

    return FileType.other;
  }

  /// Download file to local storage
  static Future<String?> downloadFile(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      return filePath;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  /// Open file with external app
  static Future<bool> openWithExternalApp(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error opening file with external app: $e');
      return false;
    }
  }

  /// Check if file can be viewed in-app
  static bool canViewInApp(FileType fileType) {
    return fileType == FileType.pdf || 
           fileType == FileType.image || 
           fileType == FileType.text ||
           fileType == FileType.csv;
  }

  /// Get file icon based on type
  static String getFileIcon(FileType fileType) {
    switch (fileType) {
      case FileType.pdf:
        return '📄';
      case FileType.image:
        return '🖼️';
      case FileType.word:
        return '📝';
      case FileType.excel:
        return '📊';
      case FileType.csv:
        return '📋';
      case FileType.powerpoint:
        return '📽️';
      case FileType.text:
        return '📃';
      case FileType.video:
        return '🎥';
      case FileType.audio:
        return '🎵';
      case FileType.other:
        return '📎';
    }
  }

  // File extension lists
  static const _pdfExtensions = ['pdf'];
  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
  static const _wordExtensions = ['doc', 'docx', 'odt', 'rtf'];
  static const _excelExtensions = ['xls', 'xlsx', 'ods'];
  static const _csvExtensions = ['csv'];
  static const _powerpointExtensions = ['ppt', 'pptx', 'odp'];
  static const _textExtensions = ['txt', 'md', 'log', 'json', 'xml'];
  static const _videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv'];
  static const _audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
}
