import 'package:admin/models/subcontract_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/subcontract_service.dart';
import 'package:admin/services/api_service.dart';

class SubcontractProvider extends BasePaginatedProvider<SubcontractWorkOrder> {
  final SubcontractService _service = SubcontractService(ApiService());

  @override
  Future<PaginatedResponse<SubcontractWorkOrder>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchSubcontracts(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Subcontract-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByWorkOrderNumber(String? workOrderNumber) {
    updateFilter('workOrderNumber', workOrderNumber);
  }

  void filterByContractorName(String? contractorName) {
    updateFilter('contractorName', contractorName);
  }

  void filterByWorkType(String? workType) {
    updateFilter('workType', workType);
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
    String? workOrderNumber,
    String? contractorName,
    String? workType,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};

    if (projectId != null) filters['projectId'] = projectId;
    if (workOrderNumber != null) filters['workOrderNumber'] = workOrderNumber;
    if (contractorName != null) filters['contractorName'] = contractorName;
    if (workType != null) filters['workType'] = workType;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;

    applyFilters(filters);
  }
}
