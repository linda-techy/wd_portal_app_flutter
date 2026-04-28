import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/models/paginated_response.dart';

class LeadQuotationService {
  final ApiService _apiService = ApiService();

  Future<LeadQuotation> getQuotationById(int id) async {
    final response = await _apiService.get('/leads/quotations/$id');
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<List<LeadQuotation>> getQuotationsByLead(int leadId) async {
    final response = await _apiService.get('/leads/quotations/lead/$leadId');
    return _apiService.unwrapList<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json));
  }

  Future<LeadQuotation> createQuotation(LeadQuotation quotation) async {
    final response = await _apiService.post('/leads/quotations',
        data: quotation.toCreateJson());
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<LeadQuotation> updateQuotation(int id, LeadQuotation quotation) async {
    final response = await _apiService.put('/leads/quotations/$id',
        data: quotation.toCreateJson());
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<LeadQuotation> sendQuotation(int id) async {
    final response =
        await _apiService.post('/leads/quotations/$id/send', data: {});
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<LeadQuotation> acceptQuotation(int id) async {
    final response =
        await _apiService.post('/leads/quotations/$id/accept', data: {});
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<LeadQuotation> rejectQuotation(int id, {String? reason}) async {
    final response = await _apiService.post('/leads/quotations/$id/reject',
        data: reason != null ? {'reason': reason} : {});
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteQuotation(int id) async {
    try {
      await _apiService.delete('/leads/quotations/$id');
    } catch (e) {
      throw Exception('Failed to delete quotation: $e');
    }
  }

  /// Restore a soft-deleted quotation. Used by the Undo snackbar after
  /// a delete on the list / detail screen. Backend clears the deleted_at
  /// tombstone and returns the restored row; we ignore the body and
  /// just check for success.
  Future<void> restoreQuotation(int id) async {
    await _apiService.post('/leads/quotations/$id/restore', data: {});
  }

  /// Pipeline summary — feeds the list screen's hero card.
  /// Returns a raw JSON map; the calling provider parses it into typed
  /// fields. Backend shape matches PipelineSummaryResponse.java.
  Future<Map<String, dynamic>> getPipelineSummary() async {
    final response = await _apiService.get('/leads/quotations/pipeline-summary');
    return _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  /// Duplicate an existing quotation as a fresh DRAFT. Returns the new
  /// quotation. Backend regenerates the quotation number and resets the
  /// lifecycle (no sentAt/respondedAt) but copies header, pricing, items.
  Future<LeadQuotation> duplicateQuotation(int sourceId) async {
    final response = await _apiService.post(
        '/leads/quotations/$sourceId/duplicate',
        data: {});
    return _apiService.unwrap<LeadQuotation>(
        response, (json) => LeadQuotation.fromJson(json as Map<String, dynamic>));
  }

  /// Download quotation PDF for client presentation
  Future<Uint8List> downloadQuotationPdf(int id) async {
    final response = await _apiService.get(
      '/leads/quotations/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  /// NEW: Standardized search endpoint for lead quotations
  Future<PaginatedResponse<LeadQuotation>> searchLeadQuotations({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response = await _apiService.get('/leads/quotations/search',
        queryParams: queryParams);
    // Backend returns ApiResponse<Page<LeadQuotation>>, unwrap extracts the Page object
    return _apiService.unwrap<PaginatedResponse<LeadQuotation>>(
      response,
      (json) {
        // Handle both direct Page format and wrapped in ApiResponse
        Map<String, dynamic> pageData;
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          // If wrapped in ApiResponse, extract data field
          pageData = json['data'] as Map<String, dynamic>;
        } else {
          pageData = json as Map<String, dynamic>;
        }
        return PaginatedResponse.fromJson(pageData, LeadQuotation.fromJson);
      },
    );
  }
}
