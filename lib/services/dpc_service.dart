import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:admin/models/dpc/dpc_customization_line.dart';
import 'package:admin/models/dpc/dpc_document.dart';
import 'package:admin/services/api_service.dart';

/// HTTP client for the DPC (Detailed Project Costing) document endpoints.
///
/// All non-binary responses follow the wrapped `ApiResponse<T>` format and are
/// unwrapped via [ApiService.unwrap] / [ApiService.unwrapList].
class DpcService {
  static final DpcService _instance = DpcService._internal();
  factory DpcService() => _instance;
  DpcService._internal();

  final ApiService _apiService = ApiService();

  // ---- Document CRUD ----

  /// Create a new DRAFT DPC document for [projectId]. Backend computes scopes
  /// from the BoQ on creation; the request body is empty.
  Future<DpcDocument> create(int projectId) async {
    final response =
        await _apiService.post('/api/projects/$projectId/dpc-documents');
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }

  /// List all DPC documents for a project (most-recent first).
  Future<List<DpcDocument>> listForProject(int projectId) async {
    final response =
        await _apiService.get('/api/projects/$projectId/dpc-documents');
    return _apiService.unwrapList<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json),
    );
  }

  /// Load the latest DPC document for the builder UI. Returns null when none
  /// exists (backend 404).
  Future<DpcDocument?> getLatest(int projectId) async {
    try {
      final response = await _apiService
          .get('/api/projects/$projectId/dpc-documents/latest');
      return _apiService.unwrap<DpcDocument>(
        response,
        (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      // ApiService translates 404 → "Resource not found"; treat as no-doc.
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Full detail of a single DPC document.
  Future<DpcDocument> getById(int id) async {
    final response = await _apiService.get('/api/dpc-documents/$id');
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PATCH header / contact / signatory fields. Returns the refreshed document.
  Future<DpcDocument> updateHeader(int id, Map<String, dynamic> patch) async {
    final response = await _apiService.dio.patch(
      '/api/dpc-documents/$id',
      data: patch,
    );
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PATCH a single scope row. The backend recomputes the master cost summary
  /// and returns the entire document.
  Future<DpcDocument> updateScope(
    int id,
    int scopeRowId,
    Map<String, dynamic> patch,
  ) async {
    final response = await _apiService.dio.patch(
      '/api/dpc-documents/$id/scopes/$scopeRowId',
      data: patch,
    );
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---- Customization lines ----

  Future<DpcCustomizationLine> addCustomization(
    int id, {
    required String title,
    required String description,
    required double amount,
    required int displayOrder,
  }) async {
    final response = await _apiService.post(
      '/api/dpc-documents/$id/customizations',
      data: {
        'title': title,
        'description': description,
        'amount': amount,
        'displayOrder': displayOrder,
      },
    );
    return _apiService.unwrap<DpcCustomizationLine>(
      response,
      (json) => DpcCustomizationLine.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DpcCustomizationLine> updateCustomization(
    int id,
    int lineId, {
    String? title,
    String? description,
    double? amount,
    int? displayOrder,
  }) async {
    final patch = <String, dynamic>{};
    if (title != null) patch['title'] = title;
    if (description != null) patch['description'] = description;
    if (amount != null) patch['amount'] = amount;
    if (displayOrder != null) patch['displayOrder'] = displayOrder;

    final response = await _apiService.dio.patch(
      '/api/dpc-documents/$id/customizations/$lineId',
      data: patch,
    );
    return _apiService.unwrap<DpcCustomizationLine>(
      response,
      (json) => DpcCustomizationLine.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteCustomization(int id, int lineId) async {
    final response = await _apiService
        .delete('/api/dpc-documents/$id/customizations/$lineId');
    _apiService.unwrap<void>(response, (_) {});
  }

  // ---- PDF preview ----

  /// Fetch raw PDF bytes for the live preview (binary, NOT wrapped in
  /// `ApiResponse`). Sets `Accept: application/pdf` and returns the raw payload.
  Future<Uint8List> previewPdf(int id) async {
    final response = await _apiService.dio.get<List<int>>(
      '/api/dpc-documents/$id/preview-pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
      ),
    );
    final data = response.data;
    if (data == null) {
      throw Exception('PDF preview returned empty body');
    }
    return Uint8List.fromList(data);
  }

  // ---- State transitions ----

  /// Flip a DRAFT to ISSUED. Backend renders the final PDF, persists it as
  /// a project document, and stamps `issuedAt` / `issuedByUserId`.
  Future<DpcDocument> issue(int id) async {
    final response = await _apiService.post('/api/dpc-documents/$id/issue');
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Branch a new DRAFT revision from an ISSUED document.
  Future<DpcDocument> createNewRevision(int previousId) async {
    final response =
        await _apiService.post('/api/dpc-documents/$previousId/new-revision');
    return _apiService.unwrap<DpcDocument>(
      response,
      (json) => DpcDocument.fromJson(json as Map<String, dynamic>),
    );
  }
}
