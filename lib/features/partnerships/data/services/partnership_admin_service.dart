import 'package:admin/features/partnerships/data/models/partner_model.dart';
import 'package:admin/services/api_service.dart';

class PartnershipAdminService {
  final ApiService _api = ApiService();

  /// Paginated + filtered partner list.
  Future<Map<String, dynamic>> getPartners({
    String? status,
    String? partnershipType,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null && status != 'all') 'status': status,
      if (partnershipType != null && partnershipType != 'all') 'partnershipType': partnershipType,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await _api.get('/api/admin/partnerships', queryParams: params);
    final data = _api.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
    return data;
  }

  /// Status badge counts.
  Future<Map<String, dynamic>> getStatusCounts() async {
    final response = await _api.get('/api/admin/partnerships/counts');
    return _api.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  /// Full partner detail.
  Future<PartnerDetail> getPartnerDetail(int id) async {
    final response = await _api.get('/api/admin/partnerships/$id');
    return _api.unwrap<PartnerDetail>(
        response, (json) => PartnerDetail.fromJson(json as Map<String, dynamic>));
  }

  /// Update partner status.
  Future<void> updateStatus(int id, String status) async {
    final response = await _api.put(
      '/api/admin/partnerships/$id/status',
      data: {'status': status},
    );
    _api.unwrap<void>(response, (_) {});
  }

  /// Get partner referrals.
  Future<List<PartnerReferral>> getPartnerReferrals(int id) async {
    final response = await _api.get('/api/admin/partnerships/$id/referrals');
    return _api.unwrapList<PartnerReferral>(
        response, (json) => PartnerReferral.fromJson(json));
  }

  /// Suspend partner (soft delete).
  Future<void> suspendPartner(int id) async {
    final response = await _api.delete('/api/admin/partnerships/$id');
    _api.unwrap<void>(response, (_) {});
  }

  /// Get referring partner for a lead.
  Future<Map<String, dynamic>?> getPartnerByLead(int leadId) async {
    try {
      final response = await _api.get('/api/admin/partnerships/by-lead/$leadId');
      return _api.unwrap<Map<String, dynamic>>(
          response, (json) => json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
