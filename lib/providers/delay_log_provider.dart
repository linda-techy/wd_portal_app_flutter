import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/features/delays/data/services/delay_log_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class DelayLogProvider extends BasePaginatedProvider<DelayLog> {
  final DelayLogService _service = DelayLogService();

  @override
  Future<PaginatedResponse<DelayLog>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchDelayLogs(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // DelayLog-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByDelayType(String? delayType) {
    updateFilter('delayType', delayType);
  }

  void filterByLoggedBy(int? loggedBy) {
    updateFilter('loggedBy', loggedBy);
  }

  void filterBySeverity(String? severity) {
    updateFilter('severity', severity);
  }

  void filterByResolved(bool? resolved) {
    updateFilter('resolved', resolved);
  }

  void applyAllFilters({
    int? projectId,
    String? delayType,
    int? loggedBy,
    String? severity,
    bool? resolved,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (delayType != null) filters['delayType'] = delayType;
    if (loggedBy != null) filters['loggedBy'] = loggedBy;
    if (severity != null) filters['severity'] = severity;
    if (resolved != null) filters['resolved'] = resolved;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

