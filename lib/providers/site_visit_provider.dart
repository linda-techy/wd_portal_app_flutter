import 'package:admin/models/site_visit_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/site_visit_service.dart';

class SiteVisitProvider extends BasePaginatedProvider<SiteVisit> {
  final SiteVisitService _service = SiteVisitService();

  @override
  Future<PaginatedResponse<SiteVisit>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchSiteVisits(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // SiteVisit-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByVisitedBy(int? visitedBy) {
    updateFilter('visitedBy', visitedBy);
  }

  void filterByVisitType(String? visitType) {
    updateFilter('visitType', visitType);
  }

  void filterByVisitStatus(String? visitStatus) {
    updateFilter('visitStatus', visitStatus);
  }

  void filterByActiveOnly(bool? activeOnly) {
    updateFilter('activeOnly', activeOnly);
  }

  void applyAllFilters({
    int? projectId,
    int? visitedBy,
    String? visitType,
    String? visitStatus,
    bool? activeOnly,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (visitedBy != null) filters['visitedBy'] = visitedBy;
    if (visitType != null) filters['visitType'] = visitType;
    if (visitStatus != null) filters['visitStatus'] = visitStatus;
    if (activeOnly != null) filters['activeOnly'] = activeOnly;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

