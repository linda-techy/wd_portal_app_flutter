import 'package:admin/services/api_service.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:admin/models/consumption_report_models.dart';
import 'package:admin/models/paginated_response.dart';

class InventoryService {
  final ApiService _apiService = ApiService();

  Future<List<MaterialModel>> fetchMaterials() async {
    final response = await _apiService.get('/api/inventory/materials');
    return (response.data as List)
        .map((m) => MaterialModel.fromJson(m))
        .toList();
  }

  Future<MaterialModel> createMaterial(MaterialModel material) async {
    final response = await _apiService.post('/api/inventory/materials',
        data: material.toJson());
    return MaterialModel.fromJson(response.data);
  }

  Future<List<InventoryStock>> fetchStockByProject(int projectId) async {
    final response =
        await _apiService.get('/api/inventory/stock/project/$projectId');
    return (response.data as List)
        .map((s) => InventoryStock.fromJson(s))
        .toList();
  }

  Future<StockAdjustment> createStockAdjustment(
      StockAdjustment adjustment) async {
    final response = await _apiService.post('/api/inventory/adjustments',
        data: adjustment.toJson());
    return StockAdjustment.fromJson(response.data);
  }

  Future<List<MaterialConsumptionReport>> getConsumptionReport(
      int projectId) async {
    try {
      final response = await _apiService.get(
        '/api/inventory/reports/consumption/$projectId',
      );

      return (response.data as List)
          .map((json) => MaterialConsumptionReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch consumption report: $e');
    }
  }

  /// Update material (enterprise feature)
  Future<MaterialModel> updateMaterial(int id, MaterialModel material) async {
    final response = await _apiService.put('/api/inventory/materials/$id',
        data: material.toJson());
    return MaterialModel.fromJson(response.data);
  }

  /// Deactivate material (soft delete - enterprise pattern)
  Future<void> deactivateMaterial(int id) async {
    await _apiService.delete('/api/inventory/materials/$id');
  }

  /// NEW: Standardized search endpoint for materials
  Future<PaginatedResponse<MaterialModel>> searchMaterials({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response = await _apiService.get('/api/inventory/materials/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<MaterialModel>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, MaterialModel.fromJson),
    );
  }

  /// NEW: Standardized search endpoint for inventory stock
  Future<PaginatedResponse<InventoryStock>> searchInventoryStock({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response = await _apiService.get('/api/inventory/stock/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<InventoryStock>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, InventoryStock.fromJson),
    );
  }
}
