import 'package:admin/services/api_service.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';

class LeadQuotationService {
  final ApiService _apiService = ApiService();

  Future<List<LeadQuotation>> getQuotationsByLead(int leadId) async {
    try {
      final response = await _apiService.get('/leads/quotations/lead/$leadId');
      final List<dynamic> data = response.data;
      return data.map((json) => LeadQuotation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch quotations: $e');
    }
  }

  Future<LeadQuotation> createQuotation(LeadQuotation quotation) async {
    try {
      final response = await _apiService.post('/leads/quotations', data: quotation.toCreateJson());
      return LeadQuotation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create quotation: $e');
    }
  }

  Future<LeadQuotation> updateQuotation(int id, LeadQuotation quotation) async {
    try {
      final response = await _apiService.put('/leads/quotations/$id', data: quotation.toCreateJson());
      return LeadQuotation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update quotation: $e');
    }
  }

  Future<LeadQuotation> sendQuotation(int id) async {
    try {
      final response = await _apiService.post('/leads/quotations/$id/send', data: {});
      return LeadQuotation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send quotation: $e');
    }
  }

  Future<void> deleteQuotation(int id) async {
    try {
      await _apiService.delete('/leads/quotations/$id');
    } catch (e) {
      throw Exception('Failed to delete quotation: $e');
    }
  }
}
