import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';

class LeadQuotationProvider extends BasePaginatedProvider<LeadQuotation> {
  final LeadQuotationService _service = LeadQuotationService();

  @override
  Future<PaginatedResponse<LeadQuotation>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchLeadQuotations(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // LeadQuotation-specific convenience methods

  void filterByLeadId(int? leadId) {
    updateFilter('leadId', leadId);
  }

  void filterByQuotationNumber(String? quotationNumber) {
    updateFilter('quotationNumber', quotationNumber);
  }

  void filterByPreparedBy(int? preparedById) {
    updateFilter('preparedById', preparedById);
  }

  void filterByStatus(String? status) {
    updateFilter('status', status);
  }

  void filterByValidityStatus(String? validityStatus) {
    updateFilter('validityStatus', validityStatus);
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
    int? leadId,
    String? quotationNumber,
    int? preparedBy,
    String? status,
    String? validityStatus,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filters = <String, dynamic>{};
    
    if (leadId != null) filters['leadId'] = leadId;
    if (quotationNumber != null) filters['quotationNumber'] = quotationNumber;
    if (preparedBy != null) filters['preparedById'] = preparedBy;
    if (status != null) filters['status'] = status;
    if (validityStatus != null) filters['validityStatus'] = validityStatus;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    
    applyFilters(filters);
  }
}

