import 'package:admin/models/team_member.dart';
import 'package:admin/models/team_member_simple.dart';
import 'package:admin/models/client.dart';
import 'package:admin/models/project.dart';
import 'package:admin/models/lead.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/services/api_service.dart';

class CRMService {
  static final CRMService _instance = CRMService._internal();
  factory CRMService() => _instance;
  CRMService._internal();

  final ApiService _apiService = ApiService();

  // =====================================================
  // TEAM MEMBERS
  // =====================================================

  Future<List<TeamMemberSimple>> getTeamMembersForAssignment() async {
    try {
      final response = await _apiService.get('/users/team-members');
      final List<dynamic> data = response.data;
      return data.map((json) => TeamMemberSimple.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members for assignment: $e');
    }
  }

  Future<List<TeamMember>> getAllTeamMembers() async {
    try {
      final response = await _apiService.get('/team-members');
      final List<dynamic> data = response.data;
      return data.map((json) => TeamMember.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  Future<TeamMember> getTeamMemberById(String id) async {
    try {
      final response = await _apiService.get('/team-members/$id');
      return TeamMember.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch team member: $e');
    }
  }

  Future<TeamMember> saveTeamMember(TeamMember teamMember) async {
    try {
      final response =
          await _apiService.post('/team-members', teamMember.toJson());
      return TeamMember.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save team member: $e');
    }
  }

  Future<TeamMember> updateTeamMember(String id, TeamMember teamMember) async {
    try {
      final response =
          await _apiService.put('/team-members/$id', teamMember.toJson());
      return TeamMember.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  Future<void> deleteTeamMember(String id) async {
    try {
      await _apiService.delete('/team-members/$id');
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  // =====================================================
  // LEADS
  // =====================================================

  Future<List<Lead>> getAllLeads() async {
    try {
      final response = await _apiService.get('/leads');
      final List<dynamic> data = response.data;
      return data.map((json) => Lead.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leads: $e');
    }
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(
      PaginationParams params) async {
    try {
      final queryParams = params.toQueryParams();
      final response =
          await _apiService.get('/leads/paginated', queryParams: queryParams);
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
      final response = await _apiService.get('/leads/search?query=$query');
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

  // =====================================================
  // CLIENTS
  // =====================================================

  Future<List<Client>> getAllClients() async {
    try {
      final response = await _apiService.get('/clients');
      final List<dynamic> data = response.data;
      return data.map((json) => Client.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  Future<Client> getClientById(String id) async {
    try {
      final response = await _apiService.get('/clients/$id');
      return Client.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch client: $e');
    }
  }

  Future<Client> saveClient(Client client) async {
    try {
      final response = await _apiService.post('/clients', client.toJson());
      return Client.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save client: $e');
    }
  }

  Future<Client> updateClient(String id, Client client) async {
    try {
      final response = await _apiService.put('/clients/$id', client.toJson());
      return Client.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _apiService.delete('/clients/$id');
    } catch (e) {
      throw Exception('Failed to delete client: $e');
    }
  }

  Future<List<Client>> getClientsByAssignedTo(String assignedTo) async {
    try {
      final response = await _apiService.get('/clients/assigned/$assignedTo');
      final List<dynamic> data = response.data;
      return data.map((json) => Client.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch clients by assigned to: $e');
    }
  }

  // =====================================================
  // PROJECTS
  // =====================================================

  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _apiService.get('/projects');
      final List<dynamic> data = response.data;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  Future<Project> getProjectById(String id) async {
    try {
      final response = await _apiService.get('/projects/$id');
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  Future<Project> saveProject(Project project) async {
    try {
      final response = await _apiService.post('/projects', project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save project: $e');
    }
  }

  Future<Project> updateProject(String id, Project project) async {
    try {
      final response = await _apiService.put('/projects/$id', project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _apiService.delete('/projects/$id');
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  Future<List<Project>> getProjectsByClient(String clientId) async {
    try {
      final response = await _apiService.get('/projects/client/$clientId');
      final List<dynamic> data = response.data;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch projects by client: $e');
    }
  }

  Future<List<Project>> getProjectsByAssignedTo(String assignedTo) async {
    try {
      final response = await _apiService.get('/projects/assigned/$assignedTo');
      final List<dynamic> data = response.data;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch projects by assigned to: $e');
    }
  }

  Future<void> updateProjectProgress(
      String id, double progressPercentage) async {
    try {
      await _apiService.put(
          '/projects/$id/progress', {'progressPercentage': progressPercentage});
    } catch (e) {
      throw Exception('Failed to update project progress: $e');
    }
  }

  // =====================================================
  // DASHBOARD & ANALYTICS
  // =====================================================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      final response = await _apiService.get('/dashboard/metrics');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dashboard metrics: $e');
    }
  }

  Future<Map<String, dynamic>> getSalesPipeline() async {
    try {
      final response = await _apiService.get('/dashboard/sales-pipeline');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch sales pipeline: $e');
    }
  }

  Future<Map<String, dynamic>> getTeamPerformance() async {
    try {
      final response = await _apiService.get('/dashboard/team-performance');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch team performance: $e');
    }
  }

  Future<Map<String, dynamic>> getProjectProgressSummary() async {
    try {
      final response = await _apiService.get('/dashboard/project-progress');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch project progress summary: $e');
    }
  }
}
