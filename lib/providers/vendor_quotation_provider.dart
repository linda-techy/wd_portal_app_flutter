import 'package:admin/models/procurement_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/procurement_service.dart';

class VendorQuotationProvider extends BasePaginatedProvider<VendorQuotation> {
  final ProcurementService _service = ProcurementService();

  @override
  Future<PaginatedResponse<VendorQuotation>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchVendorQuotations(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // VendorQuotation-specific convenience methods

  void filterByVendorId(int? vendorId) {
    updateFilter('vendorId', vendorId);
  }

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByQuotationNumber(String? quotationNumber) {
    updateFilter('quotationNumber', quotationNumber);
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
    int? vendorId,
    int? projectId,
    String? quotationNumber,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (vendorId != null) filters['vendorId'] = vendorId;
    if (projectId != null) filters['projectId'] = projectId;
    if (quotationNumber != null) filters['quotationNumber'] = quotationNumber;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

