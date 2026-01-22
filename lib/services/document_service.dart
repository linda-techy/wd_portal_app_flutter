import 'dart:io';
import 'dart:typed_data';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/document_models.dart';
import 'package:dio/dio.dart';

class DocumentService {
  final ApiService _apiService = ApiService();

  Future<List<ProjectDocument>> getProjectDocuments(int projectId,
      {int? categoryId}) async {
    final response = await _apiService.get(
      '/customer-projects/$projectId/documents',
      queryParams:
          categoryId != null ? {'categoryId': categoryId.toString()} : null,
    );
    return _apiService.unwrapList(
        response, (json) => ProjectDocument.fromJson(json));
  }

  Future<List<DocumentCategory>> getCategories(int projectId) async {
    final response = await _apiService
        .get('/customer-projects/$projectId/documents/categories');
    return _apiService.unwrapList(
        response, (json) => DocumentCategory.fromJson(json));
  }

  /// Upload a document for a project
  /// Supports all platforms: Web, Android, iOS, Windows, macOS, Linux
  /// [projectId] - The project ID
  /// [file] - File object (for mobile/desktop) or null (for web)
  /// [bytes] - File bytes (for web) or null (for mobile/desktop)
  /// [fileName] - File name (required for all platforms)
  /// [categoryId] - Document category ID
  /// [description] - Optional description
  Future<ProjectDocument> uploadDocument({
    required int projectId,
    File? file,
    Uint8List? bytes,
    String? fileName,
    required int categoryId,
    String? description,
  }) async {
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
      'file': multipartFile,
      'categoryId': categoryId,
      if (description != null) 'description': description,
    });

    final response = await _apiService.post(
      '/customer-projects/$projectId/documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _apiService.unwrap(response,
        (json) => ProjectDocument.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteDocument(int projectId, int documentId) async {
    final response = await _apiService
        .delete('/customer-projects/$projectId/documents/$documentId');
    _apiService.unwrap(response, (_) {});
  }
}
