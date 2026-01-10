import 'package:admin/services/api_service.dart';
import 'package:admin/models/procurement_models.dart';

class ProcurementService {
  final ApiService _apiService = ApiService();

  Future<List<Vendor>> getVendors() async {
    final response = await _apiService.get('/api/procurement/vendors');
    return _apiService.unwrapList(response, (json) => Vendor.fromJson(json));
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _apiService.post('/api/procurement/vendors', data: vendor.toJson());
    return _apiService.unwrap(response, (json) => Vendor.fromJson(json as Map<String, dynamic>));
  }

  Future<Vendor> updateVendor(int id, Vendor vendor) async {
    final response = await _apiService.put('/api/procurement/vendors/$id', data: vendor.toJson());
    return _apiService.unwrap(response, (json) => Vendor.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deactivateVendor(int id) async {
    await _apiService.delete('/api/procurement/vendors/$id');
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await _apiService.get('/api/procurement/purchase-orders');
    // Use unwrapPagedList for Spring Data Page format (data.content)
    return _apiService.unwrapPagedList(response, (json) => PurchaseOrder.fromJson(json));
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po) async {
    final response = await _apiService.post('/api/procurement/purchase-orders', data: po.toJson());
    return _apiService.unwrap(response, (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<PurchaseOrder> updatePurchaseOrder(int id, PurchaseOrder po) async {
    final response = await _apiService.put('/api/procurement/purchase-orders/$id', data: po.toJson());
    return _apiService.unwrap(response, (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deletePurchaseOrder(int id) async {
    await _apiService.delete('/api/procurement/purchase-orders/$id');
  }

  /// Close Purchase Order (for RECEIVED status - construction workflow)
  Future<PurchaseOrder> closePurchaseOrder(int id) async {
    final response = await _apiService.post('/api/procurement/purchase-orders/$id/close');
    return _apiService.unwrap(response, (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<GoodsReceivedNote> recordGRN(Map<String, dynamic> grnData) async {
    final response = await _apiService.post('/api/procurement/grn', data: grnData);
    return _apiService.unwrap(response, (json) => GoodsReceivedNote.fromJson(json as Map<String, dynamic>));
  }

  /// Fetch all GRNs (Goods Received Notes) - Enterprise centralized list view
  Future<List<GoodsReceivedNote>> fetchAllGRNs() async {
    final response = await _apiService.get('/api/procurement/grns');
    return _apiService.unwrapList(response, (json) => GoodsReceivedNote.fromJson(json as Map<String, dynamic>));
  }
}
