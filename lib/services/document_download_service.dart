import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/config/app_config.dart';

/// Centralized service for fetching document bytes with authentication.
///
/// Uses the app's [ApiService] Dio instance which already has the
/// [AuthInterceptor] attached, so Bearer tokens are sent automatically.
class DocumentDownloadService {
  DocumentDownloadService._();

  /// Resolve a possibly-relative URL to a full URL.
  static String resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConfig.fullApiUrl}$url';
  }

  /// Fetch document bytes from [url] with authentication.
  ///
  /// The URL can be relative (e.g. `/api/storage/...`) or absolute.
  /// Returns the raw bytes of the file.
  static Future<Uint8List> fetchBytes(String url) async {
    final fullUrl = resolveUrl(url);
    final response = await ApiService().dio.get(
      fullUrl,
      options: Options(
        responseType: ResponseType.bytes,
        // Override default Accept header so we accept any content type
        headers: {'Accept': '*/*'},
      ),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  /// Guess a MIME type from a filename extension.
  static String guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
