import 'package:admin/models/dpc/dpc_scope_option.dart';
import 'package:admin/models/dpc/dpc_scope_template.dart';
import 'package:admin/services/api_service.dart';

/// HTTP client for the admin-managed DPC scope template library.
///
/// Backend route prefix: `/api/dpc-scope-templates`.
class DpcTemplateService {
  static final DpcTemplateService _instance = DpcTemplateService._internal();
  factory DpcTemplateService() => _instance;
  DpcTemplateService._internal();

  final ApiService _apiService = ApiService();

  /// List the 10 (or however many) scope templates ordered by displayOrder.
  Future<List<DpcScopeTemplate>> listTemplates() async {
    final response = await _apiService.get('/api/dpc-scope-templates');
    return _apiService.unwrapList<DpcScopeTemplate>(
      response,
      (json) => DpcScopeTemplate.fromJson(json),
    );
  }

  /// Load the full template (including options) by id.
  Future<DpcScopeTemplate> getTemplate(int id) async {
    final response = await _apiService.get('/api/dpc-scope-templates/$id');
    return _apiService.unwrap<DpcScopeTemplate>(
      response,
      (json) => DpcScopeTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Patch the editable text/list/map fields on a template (title, subtitle,
  /// intro paragraph, what-you-get bullets, quality procedures, documents
  /// you get, default brands map). Options are managed separately.
  Future<DpcScopeTemplate> updateTemplate(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final response = await _apiService.dio.patch(
      '/api/dpc-scope-templates/$id',
      data: patch,
    );
    return _apiService.unwrap<DpcScopeTemplate>(
      response,
      (json) => DpcScopeTemplate.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---- Option CRUD ---------------------------------------------------------

  /// Append a new option card to the given scope template.
  /// When [displayOrder] is null the backend appends at the end.
  Future<DpcScopeOption> addOption(
    int templateId, {
    required String code,
    required String displayName,
    String? imagePath,
    int? displayOrder,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'displayName': displayName,
    };
    if (imagePath != null && imagePath.isNotEmpty) body['imagePath'] = imagePath;
    if (displayOrder != null) body['displayOrder'] = displayOrder;

    final response = await _apiService.dio.post(
      '/api/dpc-scope-templates/$templateId/options',
      data: body,
    );
    return _apiService.unwrap<DpcScopeOption>(
      response,
      (json) => DpcScopeOption.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Patch an existing option. All fields optional; null = leave as-is.
  Future<DpcScopeOption> updateOption(
    int optionId, {
    String? code,
    String? displayName,
    String? imagePath,
    int? displayOrder,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (displayName != null) body['displayName'] = displayName;
    if (imagePath != null) body['imagePath'] = imagePath;
    if (displayOrder != null) body['displayOrder'] = displayOrder;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _apiService.dio.patch(
      '/api/dpc-scope-templates/options/$optionId',
      data: body,
    );
    return _apiService.unwrap<DpcScopeOption>(
      response,
      (json) => DpcScopeOption.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Soft-delete the option (sets `deleted_at`; row hidden from queries).
  Future<void> deleteOption(int optionId) async {
    await _apiService.dio
        .delete('/api/dpc-scope-templates/options/$optionId');
  }

  /// Reorder all active options under a scope. Pass the full ordered list
  /// of option ids — the backend rejects partial lists to avoid silent drift.
  Future<List<DpcScopeOption>> reorderOptions(
    int templateId,
    List<int> orderedOptionIds,
  ) async {
    final response = await _apiService.dio.patch(
      '/api/dpc-scope-templates/$templateId/options/reorder',
      data: {'orderedOptionIds': orderedOptionIds},
    );
    return _apiService.unwrapList<DpcScopeOption>(
      response,
      (json) => DpcScopeOption.fromJson(json),
    );
  }
}
