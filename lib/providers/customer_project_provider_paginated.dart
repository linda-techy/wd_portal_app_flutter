import 'package:admin/models/customer_project.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/customer_project_service.dart';

/// NEW Paginated Provider for Customer Projects
/// Use this for standardized pagination, search, and filters
class CustomerProjectProviderPaginated extends BasePaginatedProvider<CustomerProject> {
  final CustomerProjectService _service = CustomerProjectService();

  @override
  Future<PaginatedResponse<CustomerProject>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchProjects(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // CustomerProject-specific convenience methods

  void filterByProjectPhase(String? projectPhase) {
    updateFilter('projectPhase', projectPhase);
  }

  void filterByProjectType(String? projectType) {
    updateFilter('projectType', projectType);
  }

  void filterByContractType(String? contractType) {
    updateFilter('contractType', contractType);
  }

  void filterByManagerId(int? managerId) {
    updateFilter('managerId', managerId);
  }

  void filterByCustomerId(int? customerId) {
    updateFilter('customerId', customerId);
  }

  void filterByLocation(String? location) {
    updateFilter('location', location);
  }

  void filterByCity(String? city) {
    updateFilter('city', city);
  }

  void filterByState(String? state) {
    updateFilter('state', state);
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

  void filterByProgressRange(double? minProgress, double? maxProgress) {
    final updatedFilters = Map<String, dynamic>.from(filters);
    
    if (minProgress == null) {
      updatedFilters.remove('minProgress');
    } else {
      updatedFilters['minProgress'] = minProgress;
    }
    
    if (maxProgress == null) {
      updatedFilters.remove('maxProgress');
    } else {
      updatedFilters['maxProgress'] = maxProgress;
    }
    
    applyFilters(updatedFilters);
  }

  void applyAllFilters({
    String? projectPhase,
    String? projectType,
    String? contractType,
    int? managerId,
    int? customerId,
    String? location,
    String? city,
    String? state,
    double? minBudget,
    double? maxBudget,
    double? minProgress,
    double? maxProgress,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectPhase != null) filters['projectPhase'] = projectPhase;
    if (projectType != null) filters['projectType'] = projectType;
    if (contractType != null) filters['contractType'] = contractType;
    if (managerId != null) filters['managerId'] = managerId;
    if (customerId != null) filters['customerId'] = customerId;
    if (location != null) filters['location'] = location;
    if (city != null) filters['city'] = city;
    if (state != null) filters['state'] = state;
    if (minBudget != null) filters['minBudget'] = minBudget;
    if (maxBudget != null) filters['maxBudget'] = maxBudget;
    if (minProgress != null) filters['minProgress'] = minProgress;
    if (maxProgress != null) filters['maxProgress'] = maxProgress;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

