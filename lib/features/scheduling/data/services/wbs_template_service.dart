import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

/// Result of `POST /api/projects/{id}/wbs/clone-from-template`.
class WbsCloneSummary {
  final int milestonesCreated;
  final int tasksCreated;
  final int predecessorsCreated;

  const WbsCloneSummary({
    required this.milestonesCreated,
    required this.tasksCreated,
    required this.predecessorsCreated,
  });

  factory WbsCloneSummary.fromJson(Map<String, dynamic> j) => WbsCloneSummary(
        milestonesCreated: (j['milestonesCreated'] as num).toInt(),
        tasksCreated: (j['tasksCreated'] as num).toInt(),
        predecessorsCreated: (j['predecessorsCreated'] as num).toInt(),
      );
}

/// Admin API for `/api/wbs/templates` and `/api/projects/{id}/wbs/clone-from-template`.
///
/// All methods go through [ApiService.unwrap] / [ApiService.unwrapList] which
/// transparently handle both raw bodies (the real backend shape) and any
/// future `{success, data}` envelope, so we don't have to re-thread responses
/// if/when an envelope is introduced.
class WbsTemplateService {
  final ApiService _api;
  final Dio? _injectedDio;

  WbsTemplateService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/wbs/templates?includeInactive={includeInactive}
  ///
  /// The real backend only accepts `includeInactive`. Project-type filtering
  /// is performed client-side by the provider/screen so we don't change the
  /// UX while staying compatible with the real contract.
  Future<List<WbsTemplate>> list({bool includeInactive = false}) async {
    final response = await _dio.get(
      '/api/wbs/templates',
      queryParameters: {'includeInactive': includeInactive},
    );
    return _api.unwrapList(response, WbsTemplate.fromJson);
  }

  /// GET /api/wbs/templates/{id}
  Future<WbsTemplate> get(int id) async {
    final response = await _dio.get('/api/wbs/templates/$id');
    return _api.unwrap<WbsTemplate>(
      response,
      (json) => WbsTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/wbs/templates — server bumps `version` and inserts a new row.
  Future<WbsTemplate> createNewVersion(WbsTemplate draft) async {
    final response = await _dio.post(
      '/api/wbs/templates',
      data: draft.toJson(),
    );
    return _api.unwrap<WbsTemplate>(
      response,
      (json) => WbsTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/wbs/templates/{id} — replaces the entire template DTO.
  ///
  /// The real backend has no PATCH/toggle endpoint; toggling `isActive` is a
  /// full-DTO PUT. Callers that want to flip active are expected to fetch the
  /// current DTO, mutate it, and pass it here.
  Future<WbsTemplate> update(int id, WbsTemplate dto) async {
    final response = await _dio.put(
      '/api/wbs/templates/$id',
      data: dto.toJson(),
    );
    return _api.unwrap<WbsTemplate>(
      response,
      (json) => WbsTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  /// DELETE /api/wbs/templates/{id} — soft-delete (server enforces no-clone-yet).
  Future<void> delete(int id) async {
    await _dio.delete('/api/wbs/templates/$id');
  }

  /// POST /api/projects/{projectId}/wbs/clone-from-template
  ///
  /// Wired into the post-lead-conversion flow via
  /// `WbsTemplatePickerDialog` + `runWbsTemplatePickerFlow` (B9). Returns 409
  /// if the project already has a WBS — the caller surfaces that to the user.
  Future<WbsCloneSummary> cloneIntoProject({
    required int projectId,
    required int templateId,
    required int floorCount,
  }) async {
    final response = await _dio.post(
      '/api/projects/$projectId/wbs/clone-from-template',
      data: {'templateId': templateId, 'floorCount': floorCount},
    );
    return _api.unwrap<WbsCloneSummary>(
      response,
      (json) => WbsCloneSummary.fromJson(json as Map<String, dynamic>),
    );
  }
}
