import 'package:admin/models/procurement_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/procurement_service.dart';

class MaterialIndentProvider extends BasePaginatedProvider<MaterialIndent> {
  final ProcurementService _service = ProcurementService();

  @override
  Future<PaginatedResponse<MaterialIndent>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchMaterialIndents(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // MaterialIndent-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByRequestedById(int? requestedById) {
    updateFilter('requestedById', requestedById);
  }

  void filterByApprovedById(int? approvedById) {
    updateFilter('approvedById', approvedById);
  }

  void filterByIndentNumber(String? indentNumber) {
    updateFilter('indentNumber', indentNumber);
  }

  void filterByMaterialName(String? materialName) {
    updateFilter('materialName', materialName);
  }

  void applyAllFilters({
    int? projectId,
    int? requestedById,
    int? approvedById,
    String? indentNumber,
    String? materialName,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (requestedById != null) filters['requestedById'] = requestedById;
    if (approvedById != null) filters['approvedById'] = approvedById;
    if (indentNumber != null) filters['indentNumber'] = indentNumber;
    if (materialName != null) filters['materialName'] = materialName;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

