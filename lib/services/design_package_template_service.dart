import 'package:dio/dio.dart';
import '../models/design_package_template.dart';
import 'api_service.dart';

class DesignPackageTemplateService {
  static final DesignPackageTemplateService _instance =
      DesignPackageTemplateService._internal();
  factory DesignPackageTemplateService() => _instance;
  DesignPackageTemplateService._internal();

  final ApiService _api = ApiService();

  /// Lists templates from `/api/design-package-templates`.
  /// `activeOnly = true` returns only rows the customer app should see —
  /// useful for the Create-Design-Payment dropdown.
  Future<List<DesignPackageTemplate>> list({bool activeOnly = false}) async {
    final res = await _api.get(
      '/api/design-package-templates',
      queryParams: {'activeOnly': activeOnly},
    );
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) =>
              DesignPackageTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  Future<DesignPackageTemplate> create(DesignPackageTemplate template) async {
    final res = await _api.post(
      '/api/design-package-templates',
      data: template.toJson(),
    );
    return DesignPackageTemplate.fromJson(
        (res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  Future<DesignPackageTemplate> update(
      int id, DesignPackageTemplate template) async {
    final res = await _api.put(
      '/api/design-package-templates/$id',
      data: template.toJson(),
    );
    return DesignPackageTemplate.fromJson(
        (res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  /// Soft-archive — preferred over [delete] so historical
  /// design_package_payments rows referencing this code still render.
  Future<DesignPackageTemplate> setActive(int id, bool active) async {
    final res = await _api.dio.patch(
      '/api/design-package-templates/$id/active',
      data: {'active': active},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return DesignPackageTemplate.fromJson(
        (res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/design-package-templates/$id');
  }
}
