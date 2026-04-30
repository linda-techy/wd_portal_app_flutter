import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/models/quotation_assumption.dart';
import 'package:admin/features/leads/data/models/quotation_exclusion.dart';
import 'package:admin/features/leads/data/models/quotation_inclusion.dart';
import 'package:admin/features/leads/data/models/quotation_payment_milestone.dart';
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

  /// Walldot's 16 standard scope rows (Excavation → Hand Rails) that the
  /// SQFT_RATE add screen uses to seed a fresh quotation. Backend returns
  /// a List<{itemNumber, particulars, description}>; we keep the JSON
  /// shape raw because the only consumer (the add screen) maps it
  /// directly into LeadQuotationItem rows.
  Future<List<Map<String, dynamic>>> getStandardScopes() async {
    final response = await _apiService.get('/leads/quotations/standard-scopes');
    final data = _apiService.unwrap<List<dynamic>>(
        response, (json) => json as List<dynamic>);
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
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

  // ── V76 sub-resources: inclusions / exclusions / assumptions / milestones ──

  Future<List<QuotationInclusion>> listInclusions(int quotationId) async {
    final response =
        await _apiService.get('/leads/quotations/$quotationId/inclusions');
    final raw = _apiService.unwrap<List<dynamic>>(
        response, (json) => json as List<dynamic>);
    return raw
        .map((e) => QuotationInclusion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuotationInclusion> createInclusion(
      int quotationId, QuotationInclusion inclusion) async {
    final response = await _apiService.post(
        '/leads/quotations/$quotationId/inclusions',
        data: inclusion.toRequestJson());
    return _apiService.unwrap<QuotationInclusion>(response,
        (json) => QuotationInclusion.fromJson(json as Map<String, dynamic>));
  }

  Future<QuotationInclusion> updateInclusion(
      int quotationId, int inclusionId, QuotationInclusion inclusion) async {
    final response = await _apiService.put(
        '/leads/quotations/$quotationId/inclusions/$inclusionId',
        data: inclusion.toRequestJson());
    return _apiService.unwrap<QuotationInclusion>(response,
        (json) => QuotationInclusion.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteInclusion(int quotationId, int inclusionId) async {
    await _apiService
        .delete('/leads/quotations/$quotationId/inclusions/$inclusionId');
  }

  Future<List<QuotationExclusion>> listExclusions(int quotationId) async {
    final response =
        await _apiService.get('/leads/quotations/$quotationId/exclusions');
    final raw = _apiService.unwrap<List<dynamic>>(
        response, (json) => json as List<dynamic>);
    return raw
        .map((e) => QuotationExclusion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuotationExclusion> createExclusion(
      int quotationId, QuotationExclusion exclusion) async {
    final response = await _apiService.post(
        '/leads/quotations/$quotationId/exclusions',
        data: exclusion.toRequestJson());
    return _apiService.unwrap<QuotationExclusion>(response,
        (json) => QuotationExclusion.fromJson(json as Map<String, dynamic>));
  }

  Future<QuotationExclusion> updateExclusion(
      int quotationId, int exclusionId, QuotationExclusion exclusion) async {
    final response = await _apiService.put(
        '/leads/quotations/$quotationId/exclusions/$exclusionId',
        data: exclusion.toRequestJson());
    return _apiService.unwrap<QuotationExclusion>(response,
        (json) => QuotationExclusion.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteExclusion(int quotationId, int exclusionId) async {
    await _apiService
        .delete('/leads/quotations/$quotationId/exclusions/$exclusionId');
  }

  Future<List<QuotationAssumption>> listAssumptions(int quotationId) async {
    final response =
        await _apiService.get('/leads/quotations/$quotationId/assumptions');
    final raw = _apiService.unwrap<List<dynamic>>(
        response, (json) => json as List<dynamic>);
    return raw
        .map((e) => QuotationAssumption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuotationAssumption> createAssumption(
      int quotationId, QuotationAssumption assumption) async {
    final response = await _apiService.post(
        '/leads/quotations/$quotationId/assumptions',
        data: assumption.toRequestJson());
    return _apiService.unwrap<QuotationAssumption>(response,
        (json) => QuotationAssumption.fromJson(json as Map<String, dynamic>));
  }

  Future<QuotationAssumption> updateAssumption(
      int quotationId, int assumptionId, QuotationAssumption assumption) async {
    final response = await _apiService.put(
        '/leads/quotations/$quotationId/assumptions/$assumptionId',
        data: assumption.toRequestJson());
    return _apiService.unwrap<QuotationAssumption>(response,
        (json) => QuotationAssumption.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteAssumption(int quotationId, int assumptionId) async {
    await _apiService
        .delete('/leads/quotations/$quotationId/assumptions/$assumptionId');
  }

  /// Returns both the milestone rows and the running percentage total
  /// (server-computed) so the UI can render the "85% allocated, 15%
  /// remaining" hint without a second round-trip.
  Future<({List<QuotationPaymentMilestone> milestones, double totalPercentage})>
      listPaymentMilestones(int quotationId) async {
    final response = await _apiService
        .get('/leads/quotations/$quotationId/payment-milestones');
    final body = _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
    final rows = (body['milestones'] as List? ?? const [])
        .map((e) =>
            QuotationPaymentMilestone.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (body['totalPercentage'] as num?)?.toDouble() ?? 0.0;
    return (milestones: rows, totalPercentage: total);
  }

  Future<QuotationPaymentMilestone> createPaymentMilestone(
      int quotationId, QuotationPaymentMilestone milestone) async {
    final response = await _apiService.post(
        '/leads/quotations/$quotationId/payment-milestones',
        data: milestone.toRequestJson());
    return _apiService.unwrap<QuotationPaymentMilestone>(
        response,
        (json) => QuotationPaymentMilestone.fromJson(
            json as Map<String, dynamic>));
  }

  Future<QuotationPaymentMilestone> updatePaymentMilestone(int quotationId,
      int milestoneId, QuotationPaymentMilestone milestone) async {
    final response = await _apiService.put(
        '/leads/quotations/$quotationId/payment-milestones/$milestoneId',
        data: milestone.toRequestJson());
    return _apiService.unwrap<QuotationPaymentMilestone>(
        response,
        (json) => QuotationPaymentMilestone.fromJson(
            json as Map<String, dynamic>));
  }

  Future<void> deletePaymentMilestone(int quotationId, int milestoneId) async {
    await _apiService.delete(
        '/leads/quotations/$quotationId/payment-milestones/$milestoneId');
  }

  /// Generate (or rotate) the public_view_token for the customer-facing
  /// share link. Returns the new UUID as a string.
  Future<String> regeneratePublicToken(int quotationId) async {
    final response = await _apiService.post(
        '/leads/quotations/$quotationId/regenerate-token',
        data: {});
    final body = _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
    return body['publicViewToken'] as String;
  }

  /// Customer-side hits on the public token-gated endpoint.
  Future<int> getViewCount(int quotationId) async {
    final response =
        await _apiService.get('/leads/quotations/$quotationId/view-count');
    final body = _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
    return (body['viewCount'] as num).toInt();
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
