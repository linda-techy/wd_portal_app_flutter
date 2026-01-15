import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/labour_models.dart';

class LabourService {
  final ApiService _apiService = ApiService();

  Future<List<Labour>> getLabour() async {
    final response = await _apiService.get('/api/labour');
    return _apiService.unwrapList(response, (json) => Labour.fromJson(json));
  }

  Future<Labour> createLabour(Map<String, dynamic> labourData) async {
    final response = await _apiService.post('/api/labour', data: labourData);
    return _apiService.unwrap(
        response, (json) => Labour.fromJson(json as Map<String, dynamic>));
  }

  Future<List<LabourAttendance>> recordAttendance(
      List<Map<String, dynamic>> attendanceList) async {
    final response =
        await _apiService.post('/api/labour/attendance', data: attendanceList);
    return _apiService.unwrapList(
        response, (json) => LabourAttendance.fromJson(json));
  }

  Future<MeasurementBook> createMBEntry(Map<String, dynamic> mbData) async {
    final response = await _apiService.post('/api/labour/mb', data: mbData);
    return _apiService.unwrap(response,
        (json) => MeasurementBook.fromJson(json as Map<String, dynamic>));
  }

  Future<List<MeasurementBook>> getMBEntries(int projectId) async {
    final response = await _apiService.get('/api/labour/mb/project/$projectId');
    return _apiService.unwrapList(
        response, (json) => MeasurementBook.fromJson(json));
  }

  /// NEW: Standardized search endpoint for labour
  Future<PaginatedResponse<Labour>> searchLabour({
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
    return _apiService.unwrap<PaginatedResponse<Labour>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, Labour.fromJson),
    );
  }
}
