import 'package:admin/models/site_report_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/site_report_service.dart';

class SiteReportProvider extends BasePaginatedProvider<SiteReport> {
  final SiteReportService _service = SiteReportService();

  @override
  Future<PaginatedResponse<SiteReport>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchSiteReports(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // SiteReport-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByReportType(String? reportType) {
    updateFilter('reportType', reportType);
  }

  void filterByReportedBy(int? reportedBy) {
    updateFilter('reportedBy', reportedBy);
  }

  void filterByLocation(String? location) {
    updateFilter('location', location);
  }

  void applyAllFilters({
    int? projectId,
    String? reportType,
    int? reportedBy,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (reportType != null) filters['reportType'] = reportType;
    if (reportedBy != null) filters['reportedBy'] = reportedBy;
    if (location != null) filters['location'] = location;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

