import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admin/models/document_models.dart';
import 'package:admin/services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<ProjectDocument> _documents = [];
  List<DocumentCategory> _categories = [];
  bool _isLoading = false;

  List<ProjectDocument> get documents => _documents;
  List<DocumentCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchDocuments(int projectId, {int? categoryId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _documents = await _documentService.getProjectDocuments(projectId, categoryId: categoryId);
    } catch (e) {
      debugPrint("Error fetching documents: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories(int projectId) async {
    try {
      _categories = await _documentService.getCategories(projectId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> uploadDocument({
    required int projectId,
    required File file,
    required int categoryId,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _documentService.uploadDocument(
        projectId: projectId,
        file: file,
        categoryId: categoryId,
        description: description,
      );
      _documents.insert(0, doc);
    } catch (e) {
      debugPrint("Error uploading document: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
