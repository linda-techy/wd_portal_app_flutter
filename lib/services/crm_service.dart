import 'package:admin/models/team_member.dart';
import 'package:admin/models/team_member_simple.dart';
import 'package:admin/models/client.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/customer_role.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/project.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/models/role.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/project_summary.dart';

class CRMService {
  static final CRMService _instance = CRMService._internal();
  factory CRMService() => _instance;
  CRMService._internal();

  final ApiService _apiService = ApiService();

  // =====================================================
  // TEAM MEMBERS
  // =====================================================

  Future<List<TeamMemberSimple>> getTeamMembersForAssignment() async {
    final response = await _apiService.get('/users/team-members');
    return _apiService.unwrapList<TeamMemberSimple>(response, (json) => TeamMemberSimple.fromJson(json));
  }

  Future<List<TeamMember>> getAllTeamMembers() async {
    final response = await _apiService.get('/users/team-members');
    return _apiService.unwrapList<TeamMember>(response, (json) => TeamMember.fromJson(json));
  }

  Future<TeamMember> getTeamMemberById(String id) async {
    final response = await _apiService.get('/team-members/$id');
    return _apiService.unwrap<TeamMember>(response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  Future<TeamMember> saveTeamMember(TeamMember teamMember) async {
    final response = await _apiService.post('/team-members', data: teamMember.toJson());
    return _apiService.unwrap<TeamMember>(response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  Future<TeamMember> updateTeamMember(String id, TeamMember teamMember) async {
    final response = await _apiService.put('/team-members/$id', data: teamMember.toJson());
    return _apiService.unwrap<TeamMember>(response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteTeamMember(String id) async {
    final response = await _apiService.delete('/team-members/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // =====================================================
  // LEADS
  // =====================================================

  Future<List<Lead>> getAllLeads() async {
    final response = await _apiService.get('/leads');
    return _apiService.unwrapList<Lead>(response, (json) => Lead.fromJson(json));
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(
      PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response =
        await _apiService.get('/leads/paginated', queryParams: queryParams);
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
  // CUSTOMERS
  // =====================================================

  Future<List<Customer>> getAllCustomers() async {
    final response = await _apiService.get('/customers');
    return _apiService.unwrapList<Customer>(response, (json) => Customer.fromJson(json));
  }

  Future<PaginatedResponse<Customer>> getCustomersPaginated(
      PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response = await _apiService.get('/customers/paginated',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Customer>>(response, (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, Customer.fromJson));
  }

  Future<Customer> getCustomerById(int id) async {
    final response = await _apiService.get('/customers/$id');
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response =
        await _apiService.post('/customers', data: customer.toCreateJson());
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response =
        await _apiService.put('/customers/$id', data: customer.toUpdateJson());
    return _apiService.unwrap<Customer>(response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteCustomer(int id) async {
    final response = await _apiService.delete('/customers/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<CustomerRole>> getCustomerRoles() async {
    try {
      final response = await _apiService.get('/customers/roles');
      final List<dynamic> data = response.data;
      return data.map((json) => CustomerRole.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer roles: $e');
    }
  }

  // =====================================================
  // CUSTOMER PROJECTS
  // =====================================================

  Future<ProjectSummary> getProject360(int id) async {
    final response = await _apiService.get('/projects/360/$id');
    return _apiService.unwrap<ProjectSummary>(response, (json) => ProjectSummary.fromJson(json as Map<String, dynamic>));
  }

  Future<List<CustomerProject>> getAllCustomerProjects() async {
    final response = await _apiService.get('/customer-projects');
    return _apiService.unwrapList<CustomerProject>(response, (json) => CustomerProject.fromJson(json));
  }

  Future<PaginatedResponse<CustomerProject>> getCustomerProjectsPaginated({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'desc',
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': '$sort,$direction',
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiService.get(
      '/customer-projects',
      queryParams: queryParams,
    );

    return _apiService.unwrap<PaginatedResponse<CustomerProject>>(response, (json) => PaginatedResponse.fromJson(json as Map<String, dynamic>, CustomerProject.fromJson));
  }

  Future<CustomerProject> getCustomerProjectById(int id) async {
    final response = await _apiService.get('/customer-projects/$id');
    return _apiService.unwrap<CustomerProject>(response, (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<CustomerProject> createCustomerProject(CustomerProject project) async {
    final response =
        await _apiService.post('/customer-projects', data: project.toCreateJson());
    return _apiService.unwrap<CustomerProject>(response, (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<CustomerProject> updateCustomerProject(
      int id, CustomerProject project) async {
    final response = await _apiService.put(
        '/customer-projects/$id', data: project.toUpdateJson());
    return _apiService.unwrap<CustomerProject>(response, (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteCustomerProject(int id) async {
    final response = await _apiService.delete('/customer-projects/$id');
    _apiService.unwrap<void>(response, (_) {});
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
      final response = await _apiService.post('/clients', data: client.toJson());
      return Client.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save client: $e');
    }
  }

  Future<Client> updateClient(String id, Client client) async {
    try {
      final response = await _apiService.put('/clients/$id', data: client.toJson());
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
      final response = await _apiService.post('/projects', data: project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save project: $e');
    }
  }

  Future<Project> updateProject(String id, Project project) async {
    try {
      final response = await _apiService.put('/projects/$id', data: project.toJson());
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
          '/projects/$id/progress', data: {'progressPercentage': progressPercentage});
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

  // =====================================================
  // PORTAL USERS
  // =====================================================

  Future<List<PortalUser>> getAllPortalUsers() async {
    try {
      final response = await _apiService.get('/portal-users');
      final List<dynamic> data = response.data;
      return data.map((json) => PortalUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch portal users: $e');
    }
  }

  Future<PaginatedResponse<PortalUser>> getPortalUsersPaginated({
    int page = 0,
    int size = 10,
    String sort = 'id',
    String direction = 'asc',
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
        'direction': direction,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _apiService.get(
        '/portal-users/paginated',
        queryParams: queryParams,
      );
      
      return PaginatedResponse.fromJson(response.data, PortalUser.fromJson);
    } catch (e) {
      throw Exception('Failed to fetch paginated portal users: $e');
    }
  }

  Future<PortalUser> getPortalUserById(int id) async {
    try {
      final response = await _apiService.get('/portal-users/$id');
      return PortalUser.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch portal user: $e');
    }
  }

  Future<PortalUser> createPortalUser(PortalUser user) async {
    try {
      final response =
          await _apiService.post('/portal-users', data: user.toCreateJson());
      return PortalUser.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create portal user: $e');
    }
  }

  Future<PortalUser> updatePortalUser(int id, PortalUser user) async {
    try {
      final response =
          await _apiService.put('/portal-users/$id', data: user.toUpdateJson());
      return PortalUser.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update portal user: $e');
    }
  }

  Future<void> deletePortalUser(int id) async {
    try {
      await _apiService.delete('/portal-users/$id');
    } catch (e) {
      throw Exception('Failed to delete portal user: $e');
    }
  }

  Future<List<PortalRole>> getPortalRoles() async {
    try {
      final response = await _apiService.get('/portal-users/roles');
      final List<dynamic> data = response.data;
      return data.map((json) => PortalRole.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch portal roles: $e');
    }
  }
}
