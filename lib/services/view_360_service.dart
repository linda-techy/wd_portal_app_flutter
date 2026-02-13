import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/view_360_models.dart';
import 'dart:convert';

class View360Service {
  final ApiService _apiService = ApiService();

  Future<List<View360>> getToursByProject(int projectId) async {
    try {
      final response = await _apiService.get('/api/view360/project/$projectId');
      return (response.data as List)
          .map((json) => View360.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload a 360 tour
  /// Supports all platforms: Web, Android, iOS, Windows, macOS, Linux
  /// [projectId] - The project ID
  /// [title] - Tour title
  /// [description] - Optional description
  /// [location] - Optional location
  /// [captureDate] - Optional capture date
  /// [file] - File object (for mobile/desktop) or null (for web)
  /// [bytes] - File bytes (for web) or null (for mobile/desktop)
  /// [fileName] - File name (required for all platforms)
  Future<View360> uploadTour({
    required int projectId,
    required String title,
    String? description,
    String? location,
    DateTime? captureDate,
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    try {
      final Map<String, dynamic> tourData = {
        'projectId': projectId,
        'title': title,
        'description': description,
        'location': location,
        'captureDate': captureDate?.toIso8601String(),
      };

      MultipartFile multipartFile;
      String finalFileName;

      // Determine which method to use based on available data
      // Priority: bytes (web) > file path (mobile/desktop)
      if (bytes != null && fileName != null) {
        // Web platform or desktop with bytes available
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        );
        finalFileName = fileName;
      } else if (file != null) {
        // Mobile/Desktop platform with file path
        finalFileName = fileName ?? file.path.split(RegExp(r'[/\\]')).last;
        multipartFile =
            await MultipartFile.fromFile(file.path, filename: finalFileName);
      } else {
        // Error: neither bytes nor file provided
        throw Exception(
            'Either bytes+fileName (for web) or file (for mobile/desktop) must be provided');
      }

      final formData = FormData.fromMap({
        'tour': MultipartFile.fromString(
          jsonEncode(tourData),
          contentType: DioMediaType.parse('application/json'),
        ),
        'file': multipartFile,
      });

      final response = await _apiService.post(
        '/api/view360',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return View360.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTour(int id) async {
    try {
      await _apiService.delete('/api/view360/$id');
    } catch (e) {
      rethrow;
    }
  }
}
