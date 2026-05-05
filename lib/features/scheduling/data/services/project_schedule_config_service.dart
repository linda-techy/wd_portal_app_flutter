import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';

/// Service for `/api/projects/{id}/schedule-config` and
/// `/api/projects/{id}/holiday-overrides`.
///
/// All reads/writes go through [ApiService.unwrap] / [ApiService.unwrapList]
/// so both raw bodies (the real backend shape) and any future envelope are
/// handled transparently.
class ProjectScheduleConfigService {
  final ApiService _api;
  final Dio? _injectedDio;

  ProjectScheduleConfigService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/projects/{projectId}/schedule-config
  Future<ProjectScheduleConfig> get(int projectId) async {
    final response = await _dio.get('/api/projects/$projectId/schedule-config');
    return _api.unwrap<ProjectScheduleConfig>(
      response,
      (json) => ProjectScheduleConfig.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/projects/{projectId}/schedule-config
  Future<ProjectScheduleConfig> put(ProjectScheduleConfig cfg) async {
    final response = await _dio.put(
      '/api/projects/${cfg.projectId}/schedule-config',
      data: cfg.toJson(),
    );
    return _api.unwrap<ProjectScheduleConfig>(
      response,
      (json) => ProjectScheduleConfig.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/projects/{projectId}/holiday-overrides
  Future<List<ProjectHolidayOverride>> listOverrides(int projectId) async {
    final response =
        await _dio.get('/api/projects/$projectId/holiday-overrides');
    return _api.unwrapList(response, ProjectHolidayOverride.fromJson);
  }

  /// POST /api/projects/{projectId}/holiday-overrides
  ///
  /// Backend `HolidayOverrideRequest` requires `action` and `overrideDate`;
  /// `holidayId` and `overrideName` are optional. Returns the new row id
  /// (a raw `Long`), not a DTO.
  Future<int> addOverride({
    required int projectId,
    required HolidayOverrideAction action,
    required DateTime overrideDate,
    int? holidayId,
    String? overrideName,
  }) async {
    final response = await _dio.post(
      '/api/projects/$projectId/holiday-overrides',
      data: {
        'action': action.toApi(),
        'overrideDate':
            '${overrideDate.year.toString().padLeft(4, '0')}-'
            '${overrideDate.month.toString().padLeft(2, '0')}-'
            '${overrideDate.day.toString().padLeft(2, '0')}',
        if (holidayId != null) 'holidayId': holidayId,
        if (overrideName != null && overrideName.isNotEmpty)
          'overrideName': overrideName,
      },
    );
    return _api.unwrap<int>(
      response,
      (json) => (json as num).toInt(),
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
