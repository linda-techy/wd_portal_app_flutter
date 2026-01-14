import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/quality_check_service.dart';

class QualityCheckProvider extends BasePaginatedProvider<QualityCheck> {
  final QualityCheckService _service = QualityCheckService();

  @override
  Future<PaginatedResponse<QualityCheck>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchQualityChecks(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // QualityCheck-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByCheckType(String? checkType) {
    updateFilter('checkType', checkType);
  }

  void filterByResult(String? result) {
    updateFilter('result', result);
  }

  void filterByInspectorId(int? inspectorId) {
    updateFilter('inspectorId', inspectorId);
  }

  void filterByArea(String? area) {
    updateFilter('area', area);
  }

  void applyAllFilters({
    int? projectId,
    String? checkType,
    String? result,
    int? inspectorId,
    String? area,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (checkType != null) filters['checkType'] = checkType;
    if (result != null) filters['result'] = result;
    if (inspectorId != null) filters['inspectorId'] = inspectorId;
    if (area != null) filters['area'] = area;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

