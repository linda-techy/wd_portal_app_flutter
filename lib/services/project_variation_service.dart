import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';

class ProjectVariationService {
  final ApiService _apiService = ApiService();

  /// NEW: Standardized search endpoint for project variations
  Future<PaginatedResponse<dynamic>> searchProjectVariations({
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
        ? '/api/projects/$projectId/variations/search'
        : '/api/project-variations/search';

    final response = await _apiService.get(endpoint, queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<dynamic>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, (item) => item),
    );
  }
}
