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

/// Admin API for `/api/admin/wbs-templates` and `/api/projects/{id}/wbs/clone-from-template`.
class WbsTemplateService {
  final Dio _dio;
  WbsTemplateService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// GET /api/admin/wbs-templates?projectType=...&activeOnly=true
  Future<List<WbsTemplate>> list({
    WbsProjectType? projectType,
    bool activeOnly = false,
  }) async {
    final response = await _dio.get(
      '/api/admin/wbs-templates',
      queryParameters: {
        if (projectType != null) 'projectType': projectType.toApi(),
        if (activeOnly) 'activeOnly': true,
      },
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => WbsTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/admin/wbs-templates/{id}
  Future<WbsTemplate> get(int id) async {
    final response = await _dio.get('/api/admin/wbs-templates/$id');
    return WbsTemplate.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/admin/wbs-templates — server bumps `version` and inserts a new row.
  Future<WbsTemplate> createNewVersion(WbsTemplate draft) async {
    final response = await _dio.post(
      '/api/admin/wbs-templates',
      data: draft.toJson(),
    );
    return WbsTemplate.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/admin/wbs-templates/{id} — toggles `isActive` only.
  Future<WbsTemplate> setActive(int id, bool isActive) async {
    final response = await _dio.patch(
      '/api/admin/wbs-templates/$id',
      data: {'isActive': isActive},
    );
    return WbsTemplate.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/admin/wbs-templates/{id} — soft-delete (server enforces no-clone-yet).
  Future<void> delete(int id) async {
    await _dio.delete('/api/admin/wbs-templates/$id');
  }

  /// POST /api/projects/{projectId}/wbs/clone-from-template
  Future<WbsCloneSummary> cloneIntoProject({
    required int projectId,
    required int templateId,
    required int floorCount,
  }) async {
    final response = await _dio.post(
      '/api/projects/$projectId/wbs/clone-from-template',
      data: {'templateId': templateId, 'floorCount': floorCount},
    );
    return WbsCloneSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
