import 'package:admin/features/projects/data/models/project_model.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/services/api_service.dart';

class ProjectService {
  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<ProjectModel>> searchProjects({
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

    final response = await _apiService.get(
      '/customer-projects/search',
      queryParams: queryParams,
    );

    return _apiService.unwrap<PaginatedResponse<ProjectModel>>(
      response,
      (json) {
        Map<String, dynamic> pageData;
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          pageData = json['data'] as Map<String, dynamic>;
        } else {
          pageData = json as Map<String, dynamic>;
        }
        return PaginatedResponse.fromJson(pageData, ProjectModel.fromJson);
      },
    );
  }

  Future<void> deleteProject(int id) async {
    await _apiService.delete('/customer-projects/$id');
  }
}
