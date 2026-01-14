import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/crm_service.dart';

class CustomerProvider extends BasePaginatedProvider<Customer> {
  final CRMService _service = CRMService();

  @override
  Future<PaginatedResponse<Customer>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchCustomers(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Customer-specific convenience methods

  void filterByCustomerType(String? customerType) {
    updateFilter('customerType', customerType);
  }

  void filterByCity(String? city) {
    updateFilter('city', city);
  }

  void filterByState(String? state) {
    updateFilter('state', state);
  }

  void filterByActive(bool? active) {
    updateFilter('active', active);
  }

  void applyAllFilters({
    String? customerType,
    String? city,
    String? state,
    bool? active,
  }) {
    final filters = <String, dynamic>{};
    
    if (customerType != null) filters['customerType'] = customerType;
    if (city != null) filters['city'] = city;
    if (state != null) filters['state'] = state;
    if (active != null) filters['active'] = active;
    
    applyFilters(filters);
  }
}

