import 'dart:io';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/document_models.dart';
import 'package:dio/dio.dart';

class DocumentService {
  final ApiService _apiService = ApiService();

  Future<List<ProjectDocument>> getProjectDocuments(int projectId, {int? categoryId}) async {
    final response = await _apiService.get(
      '/customer-projects/$projectId/documents',
      queryParams: categoryId != null ? {'categoryId': categoryId} : null,
    );
    final List data = response.data['data'];
    return data.map((json) => ProjectDocument.fromJson(json)).toList();
  }

  Future<List<DocumentCategory>> getCategories(int projectId) async {
    final response = await _apiService.get('/customer-projects/$projectId/documents/categories');
    final List data = response.data['data'];
    return data.map((json) => DocumentCategory.fromJson(json)).toList();
  }

  Future<ProjectDocument> uploadDocument({
    required int projectId,
    required File file,
    required int categoryId,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'categoryId': categoryId,
      if (description != null) 'description': description,
    });

    final response = await _apiService.post(
      '/customer-projects/$projectId/documents',
      formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ProjectDocument.fromJson(response.data['data']);
  }
}
