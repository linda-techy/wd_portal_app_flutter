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

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await _apiService.get('/api/procurement/purchase-orders');
    return _apiService.unwrapList(response, (json) => PurchaseOrder.fromJson(json));
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po) async {
    final response = await _apiService.post('/api/procurement/purchase-orders', data: po.toJson());
    return _apiService.unwrap(response, (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<GoodsReceivedNote> recordGRN(Map<String, dynamic> grnData) async {
    final response = await _apiService.post('/api/procurement/grn', data: grnData);
    return _apiService.unwrap(response, (json) => GoodsReceivedNote.fromJson(json as Map<String, dynamic>));
  }
}
