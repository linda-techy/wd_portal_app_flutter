import 'dart:convert';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/procurement_models.dart';

class ProcurementService {
  final ApiService _apiService = ApiService();

  Future<List<Vendor>> getVendors() async {
    final response = await _apiService.get('/api/procurement/vendors');
    return (response.data as List).map((v) => Vendor.fromJson(v)).toList();
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _apiService.post('/api/procurement/vendors', vendor.toJson());
    return Vendor.fromJson(response.data);
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await _apiService.get('/api/procurement/purchase-orders');
    return (response.data as List).map((p) => PurchaseOrder.fromJson(p)).toList();
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po) async {
    final response = await _apiService.post('/api/procurement/purchase-orders', po.toJson());
    return PurchaseOrder.fromJson(response.data);
  }

  Future<dynamic> recordGRN(Map<String, dynamic> grnData) async {
    final response = await _apiService.post('/api/procurement/grn', grnData);
    return response.data;
  }
}
