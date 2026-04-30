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

  /// Returns only internal portal staff (company employees).
  /// Uses /users/portal-staff to exclude customer accounts from the list.
  Future<List<TeamMemberSimple>> getTeamMembersForAssignment() async {
    final response = await _apiService.get('/users/portal-staff');
    return _apiService.unwrapList<TeamMemberSimple>(
        response, (json) => TeamMemberSimple.fromJson(json));
  }

  Future<List<TeamMember>> getAllTeamMembers() async {
    final response = await _apiService.get('/users/team-members');
    return _apiService.unwrapList<TeamMember>(
        response, (json) => TeamMember.fromJson(json));
  }

  Future<TeamMember> getTeamMemberById(String id) async {
    final response = await _apiService.get('/team-members/$id');
    return _apiService.unwrap<TeamMember>(
        response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  /// Portal API doesn't expose a dedicated /team-members mutation endpoint —
  /// team members are Portal Users under the hood. Map to /portal-users.
  Map<String, dynamic> _portalUserPayload(TeamMember t, {String? password}) {
    return {
      if (t.email != null) 'email': t.email,
      if (t.firstName != null) 'first_name': t.firstName,
      if (t.lastName != null) 'last_name': t.lastName,
      'enabled': t.isActive ?? true,
      if (password != null && password.isNotEmpty) 'password': password,
      if (t.roleId != null) 'role_id': t.roleId,
    };
  }

  Future<TeamMember> saveTeamMember(TeamMember teamMember) async {
    // New portal users require a password. Callers that omit it fall back to
    // a generated temporary so the POST doesn't 400.
    final password = 'Welcome@${DateTime.now().millisecondsSinceEpoch}';
    final response = await _apiService.post(
      '/portal-users',
      data: _portalUserPayload(teamMember, password: password),
    );
    return _apiService.unwrap<TeamMember>(
        response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  Future<TeamMember> updateTeamMember(String id, TeamMember teamMember) async {
    final response = await _apiService.put(
      '/portal-users/$id',
      data: _portalUserPayload(teamMember),
    );
    return _apiService.unwrap<TeamMember>(
        response, (json) => TeamMember.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteTeamMember(String id) async {
    final response = await _apiService.delete('/portal-users/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // =====================================================
  // LEADS
  // =====================================================

  Future<List<Lead>> getAllLeads() async {
    // Backend doesn't support /leads, use paginated with large size
    final response = await _apiService.get('/leads/paginated?page=0&size=100');
    
    // Manually handle the PaginatedResponse structure to return just the list
    return _apiService.unwrap<List<Lead>>(response, (json) {
       // The 'json' here is the 'data' field of ApiResponse.
       // For paginated response, 'data' contains 'content' which is the list.
       if (json is Map<String, dynamic> && json.containsKey('content')) {
         final content = json['content'] as List;
         return content.map((item) => Lead.fromJson(item)).toList();
       }
       return [];
    });
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(
      PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response =
        await _apiService.get('/leads/paginated', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Lead>>(
        response,
        (json) => PaginatedResponse.fromJson(
            json as Map<String, dynamic>, Lead.fromJson));
  }

  Future<Lead> getLeadById(String id) async {
    final response = await _apiService.get('/leads/$id');
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> createLead(Lead lead) async {
    final response =
        await _apiService.post('/leads', data: lead.toCreateJson());
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> updateLead(String id, Lead lead) async {
    final response =
        await _apiService.put('/leads/$id', data: lead.toUpdateJson());
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteLead(String id) async {
    final response = await _apiService.delete('/leads/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<Lead>> getLeadsByStatus(String status) async {
    final response = await _apiService.get('/leads/status/$status');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getLeadsByAssignedTo(String teamMemberId) async {
    final response = await _apiService.get('/leads/assigned/$teamMemberId');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> searchLeads(String query) async {
    final response = await _apiService.get('/leads/search?query=$query');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getOverdueFollowUps() async {
    final response = await _apiService.get('/leads/overdue-followups');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  // =====================================================
  // CUSTOMERS
  // =====================================================

  Future<List<Customer>> getAllCustomers() async {
    final response = await _apiService.get('/customers');
    return _apiService.unwrapList<Customer>(
        response, (json) => Customer.fromJson(json));
  }

  Future<PaginatedResponse<Customer>> getCustomersPaginated(
      PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response =
        await _apiService.get('/customers/paginated', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Customer>>(
        response,
        (json) => PaginatedResponse.fromJson(
            json as Map<String, dynamic>, Customer.fromJson));
  }

  /// NEW: Standardized search endpoint for customers
  Future<PaginatedResponse<Customer>> searchCustomers({
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

    final response =
        await _apiService.get('/customers/search', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Customer>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, Customer.fromJson),
    );
  }

  Future<Customer> getCustomerById(int id) async {
    final response = await _apiService.get('/customers/$id');
    return _apiService.unwrap<Customer>(
        response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response =
        await _apiService.post('/customers', data: customer.toCreateJson());
    return _apiService.unwrap<Customer>(
        response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response =
        await _apiService.put('/customers/$id', data: customer.toUpdateJson());
    return _apiService.unwrap<Customer>(
        response, (json) => Customer.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteCustomer(int id) async {
    final response = await _apiService.delete('/customers/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<CustomerRole>> getCustomerRoles() async {
    final response = await _apiService.get('/customers/roles');
    return _apiService.unwrapList<CustomerRole>(
        response, (json) => CustomerRole.fromJson(json));
  }

  // =====================================================
  // CUSTOMER PROJECTS
  // =====================================================

  Future<ProjectSummary> getProject360(int id) async {
    final response = await _apiService.get('/api/projects/360/$id');
    return _apiService.unwrap<ProjectSummary>(response,
        (json) => ProjectSummary.fromJson(json as Map<String, dynamic>));
  }

  Future<List<CustomerProject>> getAllCustomerProjects() async {
    final response = await _apiService.get(
      '/customer-projects',
      queryParams: {'page': '0', 'size': '500', 'sort': 'id,asc'},
    );
    // The endpoint returns a paginated wrapper; extract the content list.
    return _apiService.unwrap<List<CustomerProject>>(response, (json) {
      if (json is Map<String, dynamic> && json.containsKey('content')) {
        final content = json['content'] as List;
        return content.map((item) => CustomerProject.fromJson(item)).toList();
      }
      // Fallback: if the response is already a flat list (legacy)
      if (json is List) {
        return json.map((item) => CustomerProject.fromJson(item)).toList();
      }
      return <CustomerProject>[];
    });
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

    return _apiService.unwrap<PaginatedResponse<CustomerProject>>(
        response,
        (json) => PaginatedResponse.fromJson(
            json as Map<String, dynamic>, CustomerProject.fromJson));
  }

  Future<CustomerProject> getCustomerProjectById(int id) async {
    final response = await _apiService.get('/customer-projects/$id');
    return _apiService.unwrap<CustomerProject>(response,
        (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<CustomerProject> createCustomerProject(CustomerProject project) async {
    final response = await _apiService.post('/customer-projects',
        data: project.toCreateJson());
    return _apiService.unwrap<CustomerProject>(response,
        (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<CustomerProject> updateCustomerProject(
      int id, CustomerProject project) async {
    final response = await _apiService.put('/customer-projects/$id',
        data: project.toUpdateJson());
    return _apiService.unwrap<CustomerProject>(response,
        (json) => CustomerProject.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteCustomerProject(int id) async {
    final response = await _apiService.delete('/customer-projects/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // =====================================================
  // CLIENTS
  // =====================================================

  Future<List<Client>> getAllClients() async {
    final response = await _apiService.get('/clients');
    return _apiService.unwrapList<Client>(
        response, (json) => Client.fromJson(json));
  }

  Future<Client> getClientById(String id) async {
    final response = await _apiService.get('/clients/$id');
    return _apiService.unwrap<Client>(
        response, (json) => Client.fromJson(json as Map<String, dynamic>));
  }

  Future<Client> saveClient(Client client) async {
    final response = await _apiService.post('/clients', data: client.toJson());
    return _apiService.unwrap<Client>(
        response, (json) => Client.fromJson(json as Map<String, dynamic>));
  }

  Future<Client> updateClient(String id, Client client) async {
    final response =
        await _apiService.put('/clients/$id', data: client.toJson());
    return _apiService.unwrap<Client>(
        response, (json) => Client.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteClient(String id) async {
    final response = await _apiService.delete('/clients/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<Client>> getClientsByAssignedTo(String assignedTo) async {
    final response = await _apiService.get('/clients/assigned/$assignedTo');
    return _apiService.unwrapList<Client>(
        response, (json) => Client.fromJson(json));
  }

  // =====================================================
  // PROJECTS
  // =====================================================

  Future<List<Project>> getAllProjects() async {
    final response = await _apiService.get('/projects');
    return _apiService.unwrapList<Project>(
        response, (json) => Project.fromJson(json));
  }

  Future<Project> getProjectById(String id) async {
    final response = await _apiService.get('/projects/$id');
    return _apiService.unwrap<Project>(
        response, (json) => Project.fromJson(json as Map<String, dynamic>));
  }

  Future<Project> saveProject(Project project) async {
    final response =
        await _apiService.post('/projects', data: project.toJson());
    return _apiService.unwrap<Project>(
        response, (json) => Project.fromJson(json as Map<String, dynamic>));
  }

  Future<Project> updateProject(String id, Project project) async {
    final response =
        await _apiService.put('/projects/$id', data: project.toJson());
    return _apiService.unwrap<Project>(
        response, (json) => Project.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteProject(String id) async {
    final response = await _apiService.delete('/projects/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<Project>> getProjectsByClient(String clientId) async {
    final response = await _apiService.get('/projects/client/$clientId');
    return _apiService.unwrapList<Project>(
        response, (json) => Project.fromJson(json));
  }

  Future<List<Project>> getProjectsByAssignedTo(String assignedTo) async {
    final response = await _apiService.get('/projects/assigned/$assignedTo');
    return _apiService.unwrapList<Project>(
        response, (json) => Project.fromJson(json));
  }

  Future<void> updateProjectProgress(
      String id, double progressPercentage) async {
    final response = await _apiService.put('/projects/$id/progress',
        data: {'progressPercentage': progressPercentage});
    _apiService.unwrap<void>(response, (_) {});
  }

  // =====================================================
  // DASHBOARD & ANALYTICS
  // =====================================================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _apiService.get('/dashboard/metrics');
    return _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSalesPipeline() async {
    final response = await _apiService.get('/dashboard/sales-pipeline');
    return _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTeamPerformance() async {
    final response = await _apiService.get('/dashboard/team-performance');
    return _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getProjectProgressSummary() async {
    final response = await _apiService.get('/dashboard/project-progress');
    return _apiService.unwrap<Map<String, dynamic>>(
        response, (json) => json as Map<String, dynamic>);
  }

  // =====================================================
  // PORTAL USERS
  // =====================================================

  Future<List<PortalUser>> getAllPortalUsers() async {
    final response = await _apiService.get('/portal-users');
    return _apiService.unwrapList<PortalUser>(
        response, (json) => PortalUser.fromJson(json));
  }

  Future<PaginatedResponse<PortalUser>> getPortalUsersPaginated({
    int page = 0,
    int size = 10,
    String sort = 'id',
    String direction = 'asc',
    String? search,
  }) async {
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

    return _apiService.unwrap<PaginatedResponse<PortalUser>>(
        response,
        (json) => PaginatedResponse.fromJson(
            json as Map<String, dynamic>, PortalUser.fromJson));
  }

  Future<PortalUser> getPortalUserById(int id) async {
    final response = await _apiService.get('/portal-users/$id');
    return _apiService.unwrap<PortalUser>(
        response, (json) => PortalUser.fromJson(json as Map<String, dynamic>));
  }

  Future<PortalUser> createPortalUser(PortalUser user) async {
    final response =
        await _apiService.post('/portal-users', data: user.toCreateJson());
    return _apiService.unwrap<PortalUser>(
        response, (json) => PortalUser.fromJson(json as Map<String, dynamic>));
  }

  Future<PortalUser> updatePortalUser(int id, PortalUser user) async {
    final response =
        await _apiService.put('/portal-users/$id', data: user.toUpdateJson());
    return _apiService.unwrap<PortalUser>(
        response, (json) => PortalUser.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deletePortalUser(int id) async {
    final response = await _apiService.delete('/portal-users/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<PortalRole>> getPortalRoles() async {
    final response = await _apiService.get('/portal-users/roles');
    return _apiService.unwrapList<PortalRole>(
        response, (json) => PortalRole.fromJson(json));
  }
}
