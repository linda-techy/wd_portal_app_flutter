import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/view_360_models.dart';
import 'dart:convert';

class View360Service {
  final ApiService _apiService = ApiService();

  Future<List<View360>> getToursByProject(int projectId) async {
    try {
      final response = await _apiService.get('/view360/project/$projectId');
      return (response.data as List).map((json) => View360.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<View360> uploadTour({
    required int projectId,
    required String title,
    String? description,
    String? location,
    DateTime? captureDate,
    required File file,
  }) async {
    try {
      final Map<String, dynamic> tourData = {
        'projectId': projectId,
        'title': title,
        'description': description,
        'location': location,
        'captureDate': captureDate?.toIso8601String(),
      };

      final formData = FormData.fromMap({
        'tour': MultipartFile.fromString(
          jsonEncode(tourData),
          contentType: DioMediaType.parse('application/json'),
        ),
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiService.post(
        '/view360',
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
      await _apiService.delete('/view360/$id');
    } catch (e) {
      rethrow;
    }
  }
}
