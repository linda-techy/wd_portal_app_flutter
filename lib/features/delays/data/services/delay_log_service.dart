import 'package:admin/services/api_service.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/models/paginated_response.dart';

class DelayLogService {
  final ApiService _apiService = ApiService();

  Future<List<DelayLog>> getDelays(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/delays');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => DelayLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load delays');
    }
  }

  Future<DelayLog> logDelay(DelayLog delay) async {
    final response = await _apiService.post(
      '/api/projects/${delay.projectId}/delays',
      data: delay.toJson(),
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(response.data);
    } else {
      throw Exception('Failed to log delay');
    }
  }

  Future<Map<String, dynamic>> getSummary(int projectId) async {
    final response =
        await _apiService.get('/api/projects/$projectId/delays/summary');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }
    return {};
  }

  Future<DelayLog> closeDelay(
      int projectId, int delayId, DateTime endDate) async {
    final response = await _apiService.put(
      '/api/projects/$projectId/delays/$delayId/close?endDate=${endDate.toIso8601String().substring(0, 10)}',
      data: {},
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(response.data);
    } else {
      throw Exception('Failed to close delay');
    }
  }

  Future<void> deleteDelay(int projectId, int delayId) async {
    final response =
        await _apiService.delete('/api/projects/$projectId/delays/$delayId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete delay');
    }
  }

  /// NEW: Standardized search endpoint for delay logs
  Future<PaginatedResponse<DelayLog>> searchDelayLogs({
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

    final response = await _apiService.get('/api/delay-logs/search',
        queryParams: queryParams);

    final List<dynamic> data = response.data['content'] ?? response.data;
    final items = data.map((json) => DelayLog.fromJson(json)).toList();

    final isLast = response.data['last'] ??
        (page >= (response.data['totalPages'] ?? 1) - 1);
    final isFirst = page == 0;

    return PaginatedResponse<DelayLog>(
      content: items,
      totalElements: response.data['totalElements'] ?? items.length,
      totalPages: response.data['totalPages'] ?? 1,
      currentPage: page,
      pageSize: size,
      isFirst: isFirst,
      isLast: isLast,
      hasNext: !isLast,
      hasPrevious: !isFirst,
    );
  }
}
