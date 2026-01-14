import 'package:admin/features/warranties/data/models/project_warranty.dart';
import 'package:admin/features/warranties/data/services/warranty_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class ProjectWarrantyProvider extends BasePaginatedProvider<ProjectWarranty> {
  final WarrantyService _service = WarrantyService();

  @override
  Future<PaginatedResponse<ProjectWarranty>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchProjectWarranties(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // ProjectWarranty-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByWarrantyType(String? warrantyType) {
    updateFilter('warrantyType', warrantyType);
  }

  void filterByStatus(String? status) {
    updateFilter('status', status);
  }

  void applyAllFilters({
    int? projectId,
    String? warrantyType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (warrantyType != null) filters['warrantyType'] = warrantyType;
    if (status != null) filters['status'] = status;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    
    applyFilters(filters);
  }
}

