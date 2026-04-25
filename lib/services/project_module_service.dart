import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/http_interceptor.dart';
import 'package:admin/models/project_document.dart';
import 'package:admin/models/document_category.dart';
import 'package:admin/config/app_config.dart';
import 'dart:io';
import 'dart:typed_data';

class ProjectModuleService {
  static final ProjectModuleService _instance =
      ProjectModuleService._internal();
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
      final response = await _apiService
          .get('/customer-projects/$projectId/documents/categories');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> categories = response.data['data'];
        return categories
            .map((json) => DocumentCategory.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch document categories: $e');
    }
  }

  // Get project documents
  Future<List<ProjectDocument>> getProjectDocuments(int projectId,
      {int? categoryId}) async {
    try {
      final queryParams =
          categoryId != null ? {'categoryId': categoryId} : null;
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

  /// Upload a document for a project
  /// Supports all platforms: Web, Android, iOS, Windows, macOS, Linux
  /// [projectId] - The project ID
  /// [file] - File object (for mobile/desktop) or null (for web)
  /// [bytes] - File bytes (for web) or null (for mobile/desktop)
  /// [fileName] - File name (required for all platforms)
  /// [categoryId] - Document category ID
  /// [description] - Optional description
  Future<ProjectDocument> uploadDocument(
    int projectId, {
    File? file,
    Uint8List? bytes,
    String? fileName,
    required int categoryId,
    String? description,
  }) async {
    try {
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

      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': multipartFile,
        'categoryId': categoryId,
        if (description != null && description.isNotEmpty)
          'description': description,
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

  // Delete a document
  Future<void> deleteDocument(int projectId, int documentId) async {
    try {
      await _apiService.delete('/customer-projects/$projectId/documents/$documentId');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Get download URL
  String getDownloadUrl(String filePath) {
    return '${AppConfig.fullApiUrl}/api/storage/$filePath';
  }
}
