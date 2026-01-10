import 'package:flutter/material.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:admin/services/inventory_service.dart';

import 'package:admin/models/consumption_report_models.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service = InventoryService();
  
  List<MaterialModel> _materials = [];
  Map<int, List<InventoryStock>> _projectStock = {};
  List<MaterialConsumptionReport>? _consumptionReports;
  bool _isLoading = false;
  String? _error;

  List<MaterialModel> get materials => _materials;
  List<MaterialConsumptionReport>? get consumptionReports => _consumptionReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<InventoryStock> getStock(int projectId) => _projectStock[projectId] ?? [];

  Future<void> fetchMaterials() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _materials = await _service.fetchMaterials();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMaterial(MaterialModel material) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newMaterial = await _service.createMaterial(material);
      _materials.add(newMaterial);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjectStock(int projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final stock = await _service.fetchStockByProject(projectId);
      _projectStock[projectId] = stock;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStockAdjustment(StockAdjustment adjustment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createStockAdjustment(adjustment);
      // Refresh stock for the specific project
      await fetchProjectStock(adjustment.projectId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchConsumptionReport(int projectId) async {
    _isLoading = true;
    _error = null;
    _consumptionReports = null;
    notifyListeners();
    try {
      _consumptionReports = await _service.getConsumptionReport(projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update material (enterprise feature)
  Future<bool> updateMaterial(int id, MaterialModel material) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateMaterial(id, material);
      await fetchMaterials(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deactivate material (soft delete)
  Future<bool> deactivateMaterial(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deactivateMaterial(id);
      await fetchMaterials(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
