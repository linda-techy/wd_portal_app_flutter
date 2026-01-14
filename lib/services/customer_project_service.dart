import 'package:admin/services/api_service.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/project_stats.dart';
import 'package:admin/models/paginated_response.dart';

class CustomerProjectService {
  static final CustomerProjectService _instance =
      CustomerProjectService._internal();
  factory CustomerProjectService() => _instance;

  final ApiService _apiService = ApiService();

  CustomerProjectService._internal();

  /// Get paginated list of projects with optional search
  Future<PaginatedResponse<CustomerProject>> getProjects({
    String? search,
    int page = 0,
    int size = 20,
    String sortBy = 'id',
    String sortDirection = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': '$sortBy,$sortDirection',
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiService.get(
        '/customer-projects',
        queryParams: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        return PaginatedResponse.fromJson(
          response.data['data'],
          (json) => CustomerProject.fromJson(json),
        );
      }

      return PaginatedResponse.empty();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  /// Get project by ID
  Future<CustomerProject?> getProjectById(int id) async {
    try {
      final response = await _apiService.get('/customer-projects/$id');

      if (response.data != null && response.data['data'] != null) {
        return CustomerProject.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  /// Create new project
  Future<CustomerProject> createProject(CustomerProject project) async {
    try {
      final response = await _apiService.post(
        '/customer-projects',
        data: project.toCreateJson(),
      );

      if (response.data != null && response.data['data'] != null) {
        return CustomerProject.fromJson(response.data['data']);
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Update existing project
  Future<CustomerProject> updateProject(int id, CustomerProject project) async {
    try {
      final response = await _apiService.put(
        '/customer-projects/$id',
        data: project.toUpdateJson(),
      );

      if (response.data != null && response.data['data'] != null) {
        return CustomerProject.fromJson(response.data['data']);
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Delete project
  Future<void> deleteProject(int id) async {
    try {
      await _apiService.delete('/customer-projects/$id');
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Get project statistics
  Future<ProjectStats> getProjectStats() async {
    try {
      final response = await _apiService.get('/customer-projects/stats');

      if (response.data != null && response.data['data'] != null) {
        return ProjectStats.fromJson(response.data['data']);
      }

      return ProjectStats.empty();
    } catch (e) {
      throw Exception('Failed to fetch project statistics: $e');
    }
  }

  /// Get projects by lead ID
  Future<List<CustomerProject>> getProjectsByLeadId(int leadId) async {
    try {
      final response =
          await _apiService.get('/customer-projects/by-lead/$leadId');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> projects = response.data['data'];
        return projects.map((json) => CustomerProject.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch projects by lead: $e');
    }
  }

  /// NEW: Standardized search endpoint for customer projects
  Future<PaginatedResponse<CustomerProject>> searchProjects({
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

    final response = await _apiService.get('/customer-projects/search',
        queryParams: queryParams);

    if (response.data != null && response.data['data'] != null) {
      return PaginatedResponse.fromJson(
        response.data['data'],
        (json) => CustomerProject.fromJson(json),
      );
    }

    return PaginatedResponse.empty();
  }
}
