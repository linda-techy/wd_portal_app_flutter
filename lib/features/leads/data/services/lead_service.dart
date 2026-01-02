
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
    try {
      final response = await _apiService.get('/users/team-members');
      final List<dynamic> data = response.data;
      return data.map((json) => TeamMemberSimple.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members for assignment: $e');
    }
  }

  Future<List<Lead>> getAllLeads() async {
    try {
      final response = await _apiService.get('/leads');
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leads: $e');
    }
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(PaginationParams params) async {
    try {
      final queryParams = params.toQueryParams();
      final response = await _apiService.get('/leads/paginated', queryParams: queryParams);
      return PaginatedResponse.fromJson(response.data, Lead.fromJson);
    } catch (e) {
      throw Exception('Failed to fetch paginated leads: $e');
    }
  }

  Future<Lead> getLeadById(String id) async {
    try {
      final response = await _apiService.get('/leads/$id');
      return Lead.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch lead: $e');
    }
  }

  Future<Lead> createLead(Lead lead) async {
    try {
      final response = await _apiService.post('/leads', lead.toCreateJson());
      return Lead.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create lead: $e');
    }
  }

  Future<Lead> updateLead(String id, Lead lead) async {
    try {
      final response = await _apiService.put('/leads/$id', lead.toUpdateJson());
      return Lead.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update lead: $e');
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _apiService.delete('/leads/$id');
    } catch (e) {
      throw Exception('Failed to delete lead: $e');
    }
  }
  
  // Filtering & Stats methods...
  Future<List<Lead>> getLeadsByStatus(String status) async {
    try {
      final response = await _apiService.get('/leads/status/$status');
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leads by status: $e');
    }
  }

  Future<List<Lead>> getLeadsByAssignedTo(String teamMemberId) async {
    try {
      final response = await _apiService.get('/leads/assigned/$teamMemberId');
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leads by assigned to: $e');
    }
  }

  Future<List<Lead>> searchLeads(String query) async {
    try {
      final response = await _apiService.get('/leads/search', queryParams: {'query': query});
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search leads: $e');
    }
  }

  Future<List<Lead>> getOverdueFollowUps() async {
    try {
      final response = await _apiService.get('/leads/overdue-followups');
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue follow-ups: $e');
    }
  }
  Future<List<ActivityFeed>> getLeadActivities(String leadId) async {
    try {
      final response = await _apiService.get('/leads/$leadId/activities');
      final List<dynamic> data = response.data;
      return data.map((json) => ActivityFeed.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lead activities: $e');
    }
  }

  Future<void> convertLead(String leadId, Map<String, dynamic> requestData) async {
    try {
      await _apiService.post('/leads/$leadId/convert', requestData);
    } catch (e) {
      throw Exception('Failed to convert lead: $e');
    }
  }

  Future<List<LeadDocument>> getLeadDocuments(String leadId) async {
    try {
      // Assuming LeadDocumentController exposes /lead-documents/lead/{leadId}
      // I need to verify the endpoint path in LeadDocumentController.java
      // It was: @RequestMapping("/lead-documents") ... @GetMapping("/lead/{leadId}")
      final response = await _apiService.get('/api/leads/$leadId/documents');
      final List<dynamic> data = response.data;
      return data.map((json) => LeadDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lead documents: $e');
    }
  }

  Future<LeadDocument> uploadDocument(String leadId, File file, String category, String description) async {
    try {
      String fileName = file.path.split(RegExp(r'[/\\]')).last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'leadId': leadId,
        'category': category,
        'description': description,
      });
      
      final response = await _apiService.post('/api/leads/$leadId/documents', formData);
      return LeadDocument.fromJson(response.data);
      return LeadDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<LeadInteraction> createInteraction(LeadInteraction interaction) async {
    try {
      final response = await _apiService.post('/leads/interactions', interaction.toJson());
      return LeadInteraction.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create interaction: $e');
    }
  }
}
