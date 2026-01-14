import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/payment_service.dart';

class PaymentProvider extends BasePaginatedProvider<dynamic> {
  final PaymentService _service = PaymentService();

  @override
  Future<PaginatedResponse<dynamic>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchPayments(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Payment-specific convenience methods

  void filterByInvoiceNumber(String? invoiceNumber) {
    updateFilter('invoiceNumber', invoiceNumber);
  }

  void filterByCustomerId(int? customerId) {
    updateFilter('customerId', customerId);
  }

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByPaymentType(String? paymentType) {
    updateFilter('paymentType', paymentType);
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
    String? invoiceNumber,
    int? customerId,
    int? projectId,
    String? paymentType,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (invoiceNumber != null) filters['invoiceNumber'] = invoiceNumber;
    if (customerId != null) filters['customerId'] = customerId;
    if (projectId != null) filters['projectId'] = projectId;
    if (paymentType != null) filters['paymentType'] = paymentType;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

