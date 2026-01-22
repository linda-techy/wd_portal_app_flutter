import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

/// Result of extracting file data from PlatformFile
class FileUploadData {
  final File? file;
  final Uint8List? bytes;
  final String fileName;

  FileUploadData({
    this.file,
    this.bytes,
    required this.fileName,
  });

  /// Check if data is available
  bool get hasData => file != null || bytes != null;
}

/// Cross-platform file upload helper
/// Extracts file data from PlatformFile consistently across all platforms
class FileUploadHelper {
  /// Extract file data from PlatformFile
  ///
  /// Handles platform differences:
  /// - Web: Uses bytes property
  /// - Mobile/Desktop: Uses path property to create File
  ///
  /// Returns FileUploadData with file (mobile/desktop), bytes (web), and fileName
  /// Throws exception if neither bytes nor path is available
  static FileUploadData extractFileData(PlatformFile platformFile) {
    final fileName = platformFile.name;

    if (kIsWeb) {
      // Web platform: use bytes property
      if (platformFile.bytes == null) {
        throw Exception(
            'File bytes are required on web platform. File: $fileName');
      }
      return FileUploadData(
        bytes: platformFile.bytes,
        fileName: fileName,
      );
    } else {
      // Mobile/Desktop platforms: use path property
      if (platformFile.path == null) {
        // Fallback: try bytes if available (some desktop platforms support both)
        if (platformFile.bytes != null) {
          return FileUploadData(
            bytes: platformFile.bytes,
            fileName: fileName,
          );
        }
        throw Exception(
            'File path is required on mobile/desktop platforms. File: $fileName');
      }
      return FileUploadData(
        file: File(platformFile.path!),
        fileName: fileName,
      );
    }
  }

  /// Extract file data from FilePickerResult
  ///
  /// Convenience method that extracts data from the first file in the result
  /// Throws exception if result is null or empty
  static FileUploadData extractFromResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }
    return extractFileData(result.files.single);
  }
}
