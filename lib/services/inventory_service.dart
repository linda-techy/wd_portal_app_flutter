import 'package:admin/services/api_service.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:admin/models/consumption_report_models.dart';
import 'package:dio/dio.dart';

class InventoryService {
  final ApiService _apiService = ApiService();

  Future<List<MaterialModel>> fetchMaterials() async {
    final response = await _apiService.get('/api/inventory/materials');
    return (response.data as List).map((m) => MaterialModel.fromJson(m)).toList();
  }

  Future<MaterialModel> createMaterial(MaterialModel material) async {
    final response = await _apiService.post('/api/inventory/materials', material.toJson());
    return MaterialModel.fromJson(response.data);
  }

  Future<List<InventoryStock>> fetchStockByProject(int projectId) async {
    final response = await _apiService.get('/api/inventory/stock/project/$projectId');
    return (response.data as List).map((s) => InventoryStock.fromJson(s)).toList();
  }

  Future<StockAdjustment> createStockAdjustment(StockAdjustment adjustment) async {
    final response = await _apiService.post('/api/inventory/adjustments', adjustment.toJson());
    return StockAdjustment.fromJson(response.data);
  }
  Future<List<MaterialConsumptionReport>> getConsumptionReport(int projectId) async {
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
}
