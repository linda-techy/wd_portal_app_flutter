import 'package:admin/models/inventory_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/inventory_service.dart';

class InventoryStockProvider extends BasePaginatedProvider<InventoryStock> {
  final InventoryService _service = InventoryService();

  @override
  Future<PaginatedResponse<InventoryStock>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchInventoryStock(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // InventoryStock-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByMaterialId(int? materialId) {
    updateFilter('materialId', materialId);
  }

  void filterByLowStock(bool? lowStock) {
    updateFilter('lowStock', lowStock);
  }

  void filterByQuantityRange(double? minQuantity, double? maxQuantity) {
    final updatedFilters = Map<String, dynamic>.from(filters);
    
    if (minQuantity == null) {
      updatedFilters.remove('minQuantity');
    } else {
      updatedFilters['minQuantity'] = minQuantity;
    }
    
    if (maxQuantity == null) {
      updatedFilters.remove('maxQuantity');
    } else {
      updatedFilters['maxQuantity'] = maxQuantity;
    }
    
    applyFilters(updatedFilters);
  }

  void applyAllFilters({
    int? projectId,
    int? materialId,
    bool? lowStock,
    double? minQuantity,
    double? maxQuantity,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (projectId != null) filters['projectId'] = projectId;
    if (materialId != null) filters['materialId'] = materialId;
    if (lowStock != null) filters['lowStock'] = lowStock;
    if (minQuantity != null) filters['minQuantity'] = minQuantity;
    if (maxQuantity != null) filters['maxQuantity'] = maxQuantity;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

