import 'dart:io';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/document_models.dart';
import 'package:dio/dio.dart';

class DocumentService {
  final ApiService _apiService = ApiService();

  Future<List<ProjectDocument>> getProjectDocuments(int projectId, {int? categoryId}) async {
    final response = await _apiService.get(
      '/customer-projects/$projectId/documents',
      queryParams: categoryId != null ? {'categoryId': categoryId.toString()} : null,
    );
    return _apiService.unwrapList(response, (json) => ProjectDocument.fromJson(json));
  }

  Future<List<DocumentCategory>> getCategories(int projectId) async {
    final response = await _apiService.get('/customer-projects/$projectId/documents/categories');
    return _apiService.unwrapList(response, (json) => DocumentCategory.fromJson(json));
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
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _apiService.unwrap(response, (json) => ProjectDocument.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteDocument(int projectId, int documentId) async {
    final response = await _apiService.delete('/customer-projects/$projectId/documents/$documentId');
    _apiService.unwrap(response, (_) {});
  }
}
