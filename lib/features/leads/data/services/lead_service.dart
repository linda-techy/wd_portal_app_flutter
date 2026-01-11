// Extract Lead Service
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/models/team_member_simple.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/leads/data/models/activity_feed.dart';
import 'package:admin/features/leads/data/models/lead_document.dart';
import 'dart:io';
import 'package:dio/dio.dart'; // Import Dio for MultipartFile

import 'package:admin/features/leads/data/models/lead_interaction.dart';

class LeadService {
  final ApiService _apiService = ApiService();

  Future<List<TeamMemberSimple>> getTeamMembersForAssignment() async {
    final response = await _apiService.get('/users/team-members');
    return _apiService.unwrapList<TeamMemberSimple>(response, (json) => TeamMemberSimple.fromJson(json));
  }

  Future<List<Lead>> getAllLeads() async {
    final response = await _apiService.get('/leads');
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response = await _apiService.get('/leads/paginated', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Lead>>(response, (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, Lead.fromJson));
  }

  Future<Lead> getLeadById(String id) async {
    final response = await _apiService.get('/leads/$id');
    return _apiService.unwrap<Lead>(response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> createLead(Lead lead) async {
    final response = await _apiService.post('/leads', data: lead.toCreateJson());
    return _apiService.unwrap<Lead>(response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> updateLead(String id, Lead lead) async {
    final response = await _apiService.put('/leads/$id', data: lead.toUpdateJson());
    return _apiService.unwrap<Lead>(response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteLead(String id) async {
    final response = await _apiService.delete('/leads/$id');
    _apiService.unwrap<void>(response, (_) {});
  }
  
  // Filtering & Stats methods...
  Future<List<Lead>> getLeadsByStatus(String status) async {
    final response = await _apiService.get('/leads/status/$status');
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getLeadsByAssignedTo(String teamMemberId) async {
    final response = await _apiService.get('/leads/assigned/$teamMemberId');
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> searchLeads(String query) async {
    final response = await _apiService.get('/leads/search', queryParams: {'query': query});
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getOverdueFollowUps() async {
    final response = await _apiService.get('/leads/overdue-followups');
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<List<ActivityFeed>> getLeadActivities(String leadId) async {
    final response = await _apiService.get('/leads/$leadId/activities');
    return _apiService.unwrapList<ActivityFeed>(response, (json) => ActivityFeed.fromJson(json));
  }

  Future<void> convertLead(String leadId, Map<String, dynamic> requestData) async {
    final response = await _apiService.post('/leads/$leadId/convert', data: requestData);
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<LeadDocument>> getLeadDocuments(String leadId) async {
    final response = await _apiService.get('/api/leads/$leadId/documents');
    return _apiService.unwrapList<LeadDocument>(response, (json) => LeadDocument.fromJson(json));
  }

  Future<LeadDocument> uploadDocument(String leadId, File file, String category, String description) async {
    String fileName = file.path.split(RegExp(r'[/\\]')).last;
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'leadId': leadId,
      'category': category,
      'description': description,
    });
    
    final response = await _apiService.post('/api/leads/$leadId/documents', data: formData);
    return _apiService.unwrap<LeadDocument>(response, (json) => LeadDocument.fromJson(json as Map<String, dynamic>));
  }

  Future<LeadInteraction> createInteraction(LeadInteraction interaction) async {
    final response = await _apiService.post('/leads/interactions', data: interaction.toJson());
    return _apiService.unwrap<LeadInteraction>(response, (json) => LeadInteraction.fromJson(json as Map<String, dynamic>));
  }
}
