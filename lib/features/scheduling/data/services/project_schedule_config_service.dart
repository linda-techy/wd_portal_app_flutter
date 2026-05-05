import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';

class ProjectScheduleConfigService {
  final Dio _dio;
  ProjectScheduleConfigService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// GET /api/projects/{projectId}/schedule-config
  Future<ProjectScheduleConfig> get(int projectId) async {
    final response = await _dio.get('/api/projects/$projectId/schedule-config');
    return ProjectScheduleConfig.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// PUT /api/projects/{projectId}/schedule-config
  Future<ProjectScheduleConfig> put(ProjectScheduleConfig cfg) async {
    final response = await _dio.put(
      '/api/projects/${cfg.projectId}/schedule-config',
      data: cfg.toJson(),
    );
    return ProjectScheduleConfig.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// GET /api/projects/{projectId}/holiday-overrides
  Future<List<ProjectHolidayOverride>> listOverrides(int projectId) async {
    final response =
        await _dio.get('/api/projects/$projectId/holiday-overrides');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => ProjectHolidayOverride.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/projects/{projectId}/holiday-overrides
  Future<ProjectHolidayOverride> addOverride({
    required int projectId,
    required int holidayId,
    required HolidayOverrideAction action,
  }) async {
    final response = await _dio.post(
      '/api/projects/$projectId/holiday-overrides',
      data: {'holidayId': holidayId, 'action': action.toApi()},
    );
    return ProjectHolidayOverride.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// DELETE /api/projects/{projectId}/holiday-overrides/{overrideId}
  Future<void> deleteOverride({
    required int projectId,
    required int overrideId,
  }) async {
    await _dio.delete('/api/projects/$projectId/holiday-overrides/$overrideId');
  }
}
