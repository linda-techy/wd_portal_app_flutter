import 'package:admin/services/api_service.dart';
import 'package:admin/features/warranties/data/models/project_warranty.dart';
import 'package:admin/models/paginated_response.dart';

class WarrantyService {
  final ApiService _apiService = ApiService();

  Future<List<ProjectWarranty>> getWarranties(int projectId) async {
    final response =
        await _apiService.get('/api/projects/$projectId/warranties');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => ProjectWarranty.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load warranties');
    }
  }

  Future<ProjectWarranty> createWarranty(ProjectWarranty warranty) async {
    final response = await _apiService.post(
      '/api/projects/${warranty.projectId}/warranties',
      data: warranty.toJson(),
    );

    if (response.statusCode == 200) {
      return ProjectWarranty.fromJson(response.data);
    } else {
      throw Exception('Failed to create warranty');
    }
  }

  Future<void> deleteWarranty(int projectId, int warrantyId) async {
    final response = await _apiService
        .delete('/api/projects/$projectId/warranties/$warrantyId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete warranty');
    }
  }

  /// NEW: Standardized search endpoint for project warranties
  Future<PaginatedResponse<ProjectWarranty>> searchProjectWarranties({
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

    // Extract projectId from filters if it exists
    final projectId = filters?['projectId'];
    final endpoint = projectId != null
        ? '/api/projects/$projectId/warranties/search'
        : '/api/project-warranties/search';

    final response = await _apiService.get(endpoint, queryParams: queryParams);

    final List<dynamic> data = response.data['content'] ?? response.data;
    final items = data.map((json) => ProjectWarranty.fromJson(json)).toList();

    return PaginatedResponse<ProjectWarranty>(
      content: items,
      totalElements: response.data['totalElements'] ?? items.length,
      totalPages: response.data['totalPages'] ?? 1,
      size: size,
      number: page,
      numberOfElements: items.length,
      first: page == 0,
      last: response.data['last'] ?? true,
    );
  }
}
