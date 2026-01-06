import 'package:admin/services/api_service.dart';
import 'package:admin/models/site_visit_models.dart';

class SiteVisitService {
  final ApiService _apiService = ApiService();

  /// Check in to a project site with GPS coordinates
  Future<SiteVisit> checkIn(CheckInRequest request) async {
    try {
      final response = await _apiService.post('/site-visits/check-in', request.toJson());
      return SiteVisit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to check in: ${e.toString()}');
    }
  }

  /// Check out from a site visit
  Future<SiteVisit> checkOut(int visitId, CheckOutRequest request) async {
    try {
      final response = await _apiService.post('/site-visits/$visitId/check-out', request.toJson());
      return SiteVisit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to check out: ${e.toString()}');
    }
  }

  /// Get current active visit for logged-in user
  Future<SiteVisit?> getMyActiveVisit() async {
    try {
      final response = await _apiService.get('/site-visits/active');
      if (response.statusCode == 204) {
        return null; // No active visit
      }
      return SiteVisit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get active visit: ${e.toString()}');
    }
  }

  /// Get all currently active visits (admin only)
  Future<List<SiteVisit>> getAllActiveVisits() async {
    try {
      final response = await _apiService.get('/site-visits/all-active');
      return (response.data as List).map((json) => SiteVisit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get all active visits: ${e.toString()}');
    }
  }

  /// Get visits for a specific project
  Future<List<SiteVisit>> getVisitsByProject(int projectId) async {
    try {
      final response = await _apiService.get('/site-visits/project/$projectId');
      return (response.data as List).map((json) => SiteVisit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get project visits: ${e.toString()}');
    }
  }

  /// Get today's visits for a project
  Future<List<SiteVisit>> getTodaysVisits(int projectId) async {
    try {
      final response = await _apiService.get('/site-visits/project/$projectId/today');
      return (response.data as List).map((json) => SiteVisit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get today\'s visits: ${e.toString()}');
    }
  }

  /// Get visits by project and date range
  Future<List<SiteVisit>> getVisitsByProjectAndDateRange(
    int projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiService.get(
        '/site-visits/project/$projectId/range',
        queryParams: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      return (response.data as List).map((json) => SiteVisit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get visits by date range: ${e.toString()}');
    }
  }

  /// Get my visit history
  Future<List<SiteVisit>> getMyVisitHistory(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        '/site-visits/my-history',
        queryParams: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      return (response.data as List).map((json) => SiteVisit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get visit history: ${e.toString()}');
    }
  }

  /// Get a specific visit by ID
  Future<SiteVisit> getVisitById(int id) async {
    try {
      final response = await _apiService.get('/site-visits/$id');
      return SiteVisit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get visit: ${e.toString()}');
    }
  }

  /// Cancel a pending visit
  Future<void> cancelVisit(int visitId) async {
    try {
      await _apiService.delete('/site-visits/$visitId');
    } catch (e) {
      throw Exception('Failed to cancel visit: ${e.toString()}');
    }
  }

  /// Get available visit types
  Future<List<VisitTypeOption>> getVisitTypes() async {
    try {
      final response = await _apiService.get('/site-visits/types');
      return (response.data as List).map((json) => VisitTypeOption.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get visit types: ${e.toString()}');
    }
  }
}
