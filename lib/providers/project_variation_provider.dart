import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/project_variation_service.dart';

class ProjectVariationProvider extends BasePaginatedProvider<dynamic> {
  final ProjectVariationService _service = ProjectVariationService();

  @override
  Future<PaginatedResponse<dynamic>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchProjectVariations(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // ProjectVariation-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByVariationType(String? variationType) {
    updateFilter('variationType', variationType);
  }

  void filterByRequestedBy(int? requestedBy) {
    updateFilter('requestedBy', requestedBy);
  }

  void filterByApprovalStatus(String? approvalStatus) {
    updateFilter('approvalStatus', approvalStatus);
  }

  void filterByAmountRange(double? minAmount, double? maxAmount) {
    final updatedFilters = Map<String, dynamic>.from(filters);
    
    if (minAmount == null) {
      updatedFilters.remove('minAmount');
    } else {
      updatedFilters['minAmount'] = minAmount;
    }
    
    if (maxAmount == null) {
      updatedFilters.remove('maxAmount');
    } else {
      updatedFilters['maxAmount'] = maxAmount;
    }
    
    applyFilters(updatedFilters);
  }

  void applyAllFilters({
    int? projectId,
    String? variationType,
    int? requestedBy,
    String? approvalStatus,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (variationType != null) filters['variationType'] = variationType;
    if (requestedBy != null) filters['requestedBy'] = requestedBy;
    if (approvalStatus != null) filters['approvalStatus'] = approvalStatus;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

