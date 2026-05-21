import 'package:admin/services/api_service.dart';
import 'package:admin/models/site_visit_violation.dart';
import 'package:admin/models/paginated_response.dart';

class SiteVisitViolationService {
  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<SiteVisitViolation>> list({
    int? projectId,
    int? userId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (projectId != null) query['projectId'] = projectId.toString();
    if (userId != null) query['userId'] = userId.toString();
    if (from != null) query['from'] = from.toIso8601String();
    if (to != null) query['to'] = to.toIso8601String();

    final response = await _apiService.get(
      '/api/site-visit-violations',
      queryParams: query,
    );
    final body = response.data as Map<String, dynamic>;
    return PaginatedResponse<SiteVisitViolation>.fromJson(
      body,
      (json) => SiteVisitViolation.fromJson(json),
    );
  }
}
