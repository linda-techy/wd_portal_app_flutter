import 'package:flutter/material.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/services/procurement_service.dart';

class ProcurementProvider with ChangeNotifier {
  final ProcurementService _service = ProcurementService();
  
  List<Vendor> _vendors = [];
  List<PurchaseOrder> _purchaseOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Vendor> get vendors => _vendors;
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vendors = await _service.getVendors();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVendor(Vendor vendor) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.createVendor(vendor);
      await fetchVendors(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVendor(int id, Vendor vendor) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateVendor(id, vendor);
      await fetchVendors();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateVendor(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deactivateVendor(id);
      await fetchVendors();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPurchaseOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _purchaseOrders = await _service.getPurchaseOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPurchaseOrder(PurchaseOrder po) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.createPurchaseOrder(po);
      await fetchPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePurchaseOrder(int id, PurchaseOrder po) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updatePurchaseOrder(id, po);
      await fetchPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePurchaseOrder(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deletePurchaseOrder(id);
      await fetchPurchaseOrders(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Close Purchase Order (construction workflow for RECEIVED POs)
  Future<bool> closePurchaseOrder(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.closePurchaseOrder(id);
      await fetchPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordGRN(Map<String, dynamic> grnData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.recordGRN(grnData);
      await fetchPurchaseOrders(); // Refresh PO list to reflect status change
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
