import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/labour_service.dart';

class LabourProvider extends BasePaginatedProvider<dynamic> {
  final LabourService _service = LabourService();

  @override
  Future<PaginatedResponse<dynamic>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchLabour(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Labour-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByWorkerId(int? workerId) {
    updateFilter('workerId', workerId);
  }

  void filterByContractorName(String? contractorName) {
    updateFilter('contractorName', contractorName);
  }

  void filterByRole(String? role) {
    updateFilter('role', role);
  }

  void filterByEmploymentType(String? employmentType) {
    updateFilter('employmentType', employmentType);
  }

  void applyAllFilters({
    int? projectId,
    int? workerId,
    String? contractorName,
    String? role,
    String? employmentType,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (workerId != null) filters['workerId'] = workerId;
    if (contractorName != null) filters['contractorName'] = contractorName;
    if (role != null) filters['role'] = role;
    if (employmentType != null) filters['employmentType'] = employmentType;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}
