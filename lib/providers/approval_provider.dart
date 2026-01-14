import 'package:admin/models/approval_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/approval_service.dart';

class ApprovalProvider extends BasePaginatedProvider<ApprovalRequest> {
  final ApprovalService _service = ApprovalService();

  @override
  Future<PaginatedResponse<ApprovalRequest>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchApprovals(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Approval-specific convenience methods

  void filterByApproverType(String? approverType) {
    updateFilter('approverType', approverType);
  }

  void filterByModuleType(String? moduleType) {
    updateFilter('moduleType', moduleType);
  }

  void filterByApproverId(int? approverId) {
    updateFilter('approverId', approverId);
  }

  void filterByRequesterId(int? requesterId) {
    updateFilter('requesterId', requesterId);
  }

  void applyAllFilters({
    String? approverType,
    String? moduleType,
    int? approverId,
    int? requesterId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};

    if (approverType != null) filters['approverType'] = approverType;
    if (moduleType != null) filters['moduleType'] = moduleType;
    if (approverId != null) filters['approverId'] = approverId;
    if (requesterId != null) filters['requesterId'] = requesterId;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;

    applyFilters(filters);
  }
}
