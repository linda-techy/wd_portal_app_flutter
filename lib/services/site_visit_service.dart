import 'package:admin/services/api_service.dart';
import 'package:admin/models/site_visit_models.dart';

class SiteVisitService {
  final ApiService _apiService = ApiService();

  /// Check in to a project site with GPS coordinates
  Future<SiteVisit> checkIn(CheckInRequest request) async {
    final response = await _apiService.post('/site-visits/check-in', data: request.toJson());
    return _apiService.unwrap<SiteVisit>(response, (json) => SiteVisit.fromJson(json as Map<String, dynamic>));
  }

  /// Check out from a site visit
  Future<SiteVisit> checkOut(int visitId, CheckOutRequest request) async {
    final response = await _apiService.post('/site-visits/$visitId/check-out', data: request.toJson());
    return _apiService.unwrap<SiteVisit>(response, (json) => SiteVisit.fromJson(json as Map<String, dynamic>));
  }

  /// Get current active visit for logged-in user
  Future<SiteVisit?> getMyActiveVisit() async {
    final response = await _apiService.get('/site-visits/active');
    // For nullable return, we can check if response.data['data'] is null
    return _apiService.unwrap<SiteVisit?>(response, (json) {
      if (json == null) return null;
      return SiteVisit.fromJson(json as Map<String, dynamic>);
    });
  }

  /// Get all currently active visits (admin only)
  Future<List<SiteVisit>> getAllActiveVisits() async {
    final response = await _apiService.get('/site-visits/all-active');
    return _apiService.unwrapList<SiteVisit>(response, (json) => SiteVisit.fromJson(json));
  }

  /// Get visits for a specific project
  Future<List<SiteVisit>> getVisitsByProject(int projectId) async {
    final response = await _apiService.get('/site-visits/project/$projectId');
    return _apiService.unwrapList<SiteVisit>(response, (json) => SiteVisit.fromJson(json));
  }

  /// Get today's visits for a project
  Future<List<SiteVisit>> getTodaysVisits(int projectId) async {
    final response = await _apiService.get('/site-visits/project/$projectId/today');
    return _apiService.unwrapList<SiteVisit>(response, (json) => SiteVisit.fromJson(json));
  }

  /// Get visits by project and date range
  Future<List<SiteVisit>> getVisitsByProjectAndDateRange(
    int projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _apiService.get(
      '/site-visits/project/$projectId/range',
      queryParams: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return _apiService.unwrapList<SiteVisit>(response, (json) => SiteVisit.fromJson(json));
  }

  /// Get my visit history
  Future<List<SiteVisit>> getMyVisitHistory(DateTime startDate, DateTime endDate) async {
    final response = await _apiService.get(
      '/site-visits/my-history',
      queryParams: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return _apiService.unwrapList<SiteVisit>(response, (json) => SiteVisit.fromJson(json));
  }

  /// Get a specific visit by ID
  Future<SiteVisit> getVisitById(int id) async {
    final response = await _apiService.get('/site-visits/$id');
    return _apiService.unwrap<SiteVisit>(response, (json) => SiteVisit.fromJson(json as Map<String, dynamic>));
  }

  /// Cancel a pending visit
  Future<void> cancelVisit(int visitId) async {
    final response = await _apiService.delete('/site-visits/$visitId');
    _apiService.unwrap<void>(response, (_) {});
  }

  /// Get available visit types
  Future<List<VisitTypeOption>> getVisitTypes() async {
    final response = await _apiService.get('/site-visits/types');
    return _apiService.unwrapList<VisitTypeOption>(response, (json) => VisitTypeOption.fromJson(json));
  }
}
