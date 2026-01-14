import 'package:admin/models/inventory_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/inventory_service.dart';

class MaterialProvider extends BasePaginatedProvider<MaterialModel> {
  final InventoryService _service = InventoryService();

  @override
  Future<PaginatedResponse<MaterialModel>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchMaterials(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Material-specific convenience methods

  void filterByMaterialName(String? materialName) {
    updateFilter('materialName', materialName);
  }

  void filterByMaterialCode(String? materialCode) {
    updateFilter('materialCode', materialCode);
  }

  void filterByMaterialCategory(String? materialCategory) {
    updateFilter('materialCategory', materialCategory);
  }

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
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
    String? materialName,
    String? materialCode,
    String? materialCategory,
    int? projectId,
    bool? lowStock,
    double? minQuantity,
    double? maxQuantity,
    String? status,
  }) {
    final filters = <String, dynamic>{};

    if (materialName != null) filters['materialName'] = materialName;
    if (materialCode != null) filters['materialCode'] = materialCode;
    if (materialCategory != null)
      filters['materialCategory'] = materialCategory;
    if (projectId != null) filters['projectId'] = projectId;
    if (lowStock != null) filters['lowStock'] = lowStock;
    if (minQuantity != null) filters['minQuantity'] = minQuantity;
    if (maxQuantity != null) filters['maxQuantity'] = maxQuantity;
    if (status != null) filters['status'] = status;

    applyFilters(filters);
  }
}
