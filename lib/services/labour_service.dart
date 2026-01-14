import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';

class LabourService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getLabour() async {
    final response = await _apiService.get('/api/labour');
    return response.data;
  }

  Future<dynamic> createLabour(Map<String, dynamic> labourData) async {
    final response = await _apiService.post('/api/labour', data: labourData);
    return response.data;
  }

  Future<List<dynamic>> recordAttendance(
      List<Map<String, dynamic>> attendanceList) async {
    final response =
        await _apiService.post('/api/labour/attendance', data: attendanceList);
    return response.data;
  }

  Future<dynamic> createMBEntry(Map<String, dynamic> mbData) async {
    final response = await _apiService.post('/api/labour/mb', data: mbData);
    return response.data;
  }

  Future<List<dynamic>> getMBEntries(int projectId) async {
    final response = await _apiService.get('/api/labour/mb/project/$projectId');
    return response.data;
  }

  /// NEW: Standardized search endpoint for labour
  Future<PaginatedResponse<dynamic>> searchLabour({
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
        await _apiService.get('/api/labour/search', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<dynamic>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, (item) => item),
    );
  }
}
