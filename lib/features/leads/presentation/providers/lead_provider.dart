import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class LeadProvider extends BasePaginatedProvider<Lead> {
  final LeadService _leadService = LeadService();

  @override
  Future<PaginatedResponse<Lead>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _leadService.searchLeads(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Lead-specific convenience methods

  void filterByStatus(String? status) {
    if (status == null || status == 'All') {
      updateFilter('status', null);
    } else {
      updateFilter('status', status);
    }
  }

  void filterBySource(String? source) {
    updateFilter('source', source);
  }

  void filterByPriority(String? priority) {
    updateFilter('priority', priority);
  }

  void filterByCustomerType(String? customerType) {
    updateFilter('customerType', customerType);
  }

  void filterByProjectType(String? projectType) {
    updateFilter('projectType', projectType);
  }

  void filterByAssignedTeam(String? teamMemberId) {
    updateFilter('assignedTeam', teamMemberId);
  }

  void filterByLocation(String? state, String? district) {
    final updatedFilters = Map<String, dynamic>.from(filters);

    if (state == null) {
      updatedFilters.remove('state');
    } else {
      updatedFilters['state'] = state;
    }

    if (district == null) {
      updatedFilters.remove('district');
    } else {
      updatedFilters['district'] = district;
    }

    applyFilters(updatedFilters);
  }

  void filterByBudgetRange(double? minBudget, double? maxBudget) {
    final updatedFilters = Map<String, dynamic>.from(filters);

    if (minBudget == null) {
      updatedFilters.remove('minBudget');
    } else {
      updatedFilters['minBudget'] = minBudget;
    }

    if (maxBudget == null) {
      updatedFilters.remove('maxBudget');
    } else {
      updatedFilters['maxBudget'] = maxBudget;
    }

    applyFilters(updatedFilters);
  }

  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    final updatedFilters = Map<String, dynamic>.from(filters);

    if (startDate == null) {
      updatedFilters.remove('startDate');
    } else {
      updatedFilters['startDate'] = startDate;
    }

    if (endDate == null) {
      updatedFilters.remove('endDate');
    } else {
      updatedFilters['endDate'] = endDate;
    }

    applyFilters(updatedFilters);
  }

  // Apply all 12 filters at once
  void applyAllFilters({
    String? status,
    String? source,
    String? priority,
    String? customerType,
    String? projectType,
    String? assignedTeam,
    String? state,
    String? district,
    double? minBudget,
    double? maxBudget,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filters = <String, dynamic>{};

    if (status != null && status != 'All') filters['status'] = status;
    if (source != null) filters['source'] = source;
    if (priority != null) filters['priority'] = priority;
    if (customerType != null) filters['customerType'] = customerType;
    if (projectType != null) filters['projectType'] = projectType;
    if (assignedTeam != null) filters['assignedTeam'] = assignedTeam;
    if (state != null) filters['state'] = state;
    if (district != null) filters['district'] = district;
    if (minBudget != null) filters['minBudget'] = minBudget;
    if (maxBudget != null) filters['maxBudget'] = maxBudget;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;

    applyFilters(filters);
  }
}
