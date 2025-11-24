import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/http_interceptor.dart';
import 'package:admin/models/project_document.dart';
import 'package:admin/models/document_category.dart';
import 'package:admin/config/app_config.dart';
import 'dart:io';

class ProjectModuleService {
  static final ProjectModuleService _instance = ProjectModuleService._internal();
  factory ProjectModuleService() => _instance;
  
  final ApiService _apiService = ApiService();
  late final Dio _uploadDio;

  ProjectModuleService._internal() {
    // Initialize Dio for file uploads with same interceptors
    _uploadDio = Dio(BaseOptions(
      baseUrl: AppConfig.fullApiUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _uploadDio.interceptors.add(AuthInterceptor(_uploadDio));
  }

  // Get document categories
  Future<List<DocumentCategory>> getDocumentCategories(int projectId) async {
    try {
      final response = await _apiService.get('/customer-projects/$projectId/documents/categories');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> categories = response.data['data'];
        return categories.map((json) => DocumentCategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch document categories: $e');
    }
  }

  // Get project documents
  Future<List<ProjectDocument>> getProjectDocuments(int projectId, {int? categoryId}) async {
    try {
      final queryParams = categoryId != null ? {'categoryId': categoryId} : null;
      final response = await _apiService.get(
        '/customer-projects/$projectId/documents',
        queryParams: queryParams,
      );
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> documents = response.data['data'];
        return documents.map((json) => ProjectDocument.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch project documents: $e');
    }
  }

  // Upload document
  Future<ProjectDocument> uploadDocument(
    int projectId,
    File file,
    int categoryId,
    String? description,
  ) async {
    try {
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'categoryId': categoryId,
        if (description != null && description.isNotEmpty) 'description': description,
      });

      final response = await _uploadDio.post(
        '/customer-projects/$projectId/documents',
        data: formData,
      );

      if (response.data != null && response.data['data'] != null) {
        return ProjectDocument.fromJson(response.data['data']);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Get download URL
  String getDownloadUrl(String filePath) {
    return '${AppConfig.fullApiUrl}/api/storage/$filePath';
  }
}

