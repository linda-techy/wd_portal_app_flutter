import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/boq_service.dart';

class BoqProvider extends BasePaginatedProvider<BoqItem> {
  final BoqService _service = BoqService();

  @override
  Future<PaginatedResponse<BoqItem>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchBoqItems(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // BoqItem-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByWorkTypeId(int? workTypeId) {
    updateFilter('workTypeId', workTypeId);
  }

  void filterByItemCode(String? itemCode) {
    updateFilter('itemCode', itemCode);
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
    int? projectId,
    int? workTypeId,
    String? itemCode,
    double? minAmount,
    double? maxAmount,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (workTypeId != null) filters['workTypeId'] = workTypeId;
    if (itemCode != null) filters['itemCode'] = itemCode;
    if (minAmount != null) filters['minAmount'] = minAmount;
    if (maxAmount != null) filters['maxAmount'] = maxAmount;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

