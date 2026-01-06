import '../models/project_phase.dart';
import '../models/delay_log.dart';
import '../models/project_variation.dart';
import '../models/budget_models.dart';
import 'api_service.dart';

/// Service for project tracking, budget, and P/L endpoints
class ProjectTrackingService {
  final ApiService _apiService;

  ProjectTrackingService(this._apiService);

  // ===== PROJECT PHASES =====

  Future<List<ProjectPhase>> getPhases(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/tracking/phases');
    if (response.data is List) {
      return (response.data as List).map((e) => ProjectPhase.fromJson(e)).toList();
    }
    return [];
  }

  Future<ProjectPhase> createPhase(int projectId, ProjectPhase phase) async {
    final response = await _apiService.post(
      '/projects/$projectId/tracking/phases',
      data: phase.toJson(),
    );
    return ProjectPhase.fromJson(response.data);
  }

  Future<ProjectPhase> updatePhase(
    int projectId,
    int phaseId, {
    String? status,
    DateTime? actualStart,
    DateTime? actualEnd,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (actualStart != null) {
      data['actualStart'] = actualStart.toIso8601String().split('T')[0];
    }
    if (actualEnd != null) {
      data['actualEnd'] = actualEnd.toIso8601String().split('T')[0];
    }
    final response = await _apiService.put(
      '/projects/$projectId/tracking/phases/$phaseId',
      data: data,
    );
    return ProjectPhase.fromJson(response.data);
  }

  // ===== DELAY LOGS =====

  Future<List<DelayLog>> getDelayLogs(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/tracking/delays');
    if (response.data is List) {
      return (response.data as List).map((e) => DelayLog.fromJson(e)).toList();
    }
    return [];
  }

  Future<DelayLog> logDelay(int projectId, DelayLog delay) async {
    final response = await _apiService.post(
      '/projects/$projectId/tracking/delays',
      data: delay.toJson(),
    );
    return DelayLog.fromJson(response.data);
  }

  // ===== PROJECT VARIATIONS =====

  Future<List<ProjectVariation>> getVariations(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/tracking/variations');
    if (response.data is List) {
      return (response.data as List).map((e) => ProjectVariation.fromJson(e)).toList();
    }
    return [];
  }

  Future<ProjectVariation> createVariation(
    int projectId,
    ProjectVariation variation,
  ) async {
    final response = await _apiService.post(
      '/projects/$projectId/tracking/variations',
      data: variation.toJson(),
    );
    return ProjectVariation.fromJson(response.data);
  }

  Future<ProjectVariation> submitVariation(int projectId, int variationId) async {
    final response = await _apiService.put(
      '/projects/$projectId/tracking/variations/$variationId/submit',
      data: {},
    );
    return ProjectVariation.fromJson(response.data);
  }

  Future<ProjectVariation> approveVariation(
    int projectId,
    int variationId,
    int approvedById,
    bool approve,
  ) async {
    final response = await _apiService.put(
      '/projects/$projectId/tracking/variations/$variationId/approve',
      data: {
        'approvedById': approvedById,
        'approve': approve,
      },
    );
    return ProjectVariation.fromJson(response.data);
  }

  // ===== PROJECT HEALTH =====

  Future<ProjectHealthSummary> getProjectHealth(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/tracking/health');
    return ProjectHealthSummary.fromJson(response.data);
  }

  // ===== BUDGET & P/L =====

  Future<BudgetSummary> getBudgetSummary(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/budget/summary');
    return BudgetSummary.fromJson(response.data);
  }

  Future<ProjectPLSummary> getProjectPL(int projectId) async {
    final response = await _apiService.get('/projects/$projectId/budget/pl');
    return ProjectPLSummary.fromJson(response.data);
  }
}
