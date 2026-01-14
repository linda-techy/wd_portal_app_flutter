import 'package:admin/services/api_service.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/models/paginated_response.dart';

class ProcurementService {
  final ApiService _apiService = ApiService();

  Future<List<Vendor>> getVendors() async {
    final response = await _apiService.get('/api/procurement/vendors');
    return _apiService.unwrapList(response, (json) => Vendor.fromJson(json));
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    final response = await _apiService.post('/api/procurement/vendors',
        data: vendor.toJson());
    return _apiService.unwrap(
        response, (json) => Vendor.fromJson(json as Map<String, dynamic>));
  }

  Future<Vendor> updateVendor(int id, Vendor vendor) async {
    final response = await _apiService.put('/api/procurement/vendors/$id',
        data: vendor.toJson());
    return _apiService.unwrap(
        response, (json) => Vendor.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deactivateVendor(int id) async {
    await _apiService.delete('/api/procurement/vendors/$id');
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final response = await _apiService.get('/api/procurement/purchase-orders');
    // Use unwrapPagedList for Spring Data Page format (data.content)
    return _apiService.unwrapPagedList(
        response, (json) => PurchaseOrder.fromJson(json));
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po) async {
    final response = await _apiService.post('/api/procurement/purchase-orders',
        data: po.toJson());
    return _apiService.unwrap(response,
        (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<PurchaseOrder> updatePurchaseOrder(int id, PurchaseOrder po) async {
    final response = await _apiService
        .put('/api/procurement/purchase-orders/$id', data: po.toJson());
    return _apiService.unwrap(response,
        (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deletePurchaseOrder(int id) async {
    await _apiService.delete('/api/procurement/purchase-orders/$id');
  }

  /// Close Purchase Order (for RECEIVED status - construction workflow)
  Future<PurchaseOrder> closePurchaseOrder(int id) async {
    final response =
        await _apiService.post('/api/procurement/purchase-orders/$id/close');
    return _apiService.unwrap(response,
        (json) => PurchaseOrder.fromJson(json as Map<String, dynamic>));
  }

  Future<GoodsReceivedNote> recordGRN(Map<String, dynamic> grnData) async {
    final response =
        await _apiService.post('/api/procurement/grn', data: grnData);
    return _apiService.unwrap(response,
        (json) => GoodsReceivedNote.fromJson(json as Map<String, dynamic>));
  }

  /// Fetch all GRNs (Goods Received Notes) - Enterprise centralized list view
  Future<List<GoodsReceivedNote>> fetchAllGRNs() async {
    final response = await _apiService.get('/api/procurement/grns');
    return _apiService.unwrapList(response,
        (json) => GoodsReceivedNote.fromJson(json as Map<String, dynamic>));
  }

  /// NEW: Standardized search endpoint for purchase orders
  Future<PaginatedResponse<PurchaseOrder>> searchPurchaseOrders({
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

    final response = await _apiService.get('/api/purchase-orders/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<PurchaseOrder>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, PurchaseOrder.fromJson),
    );
  }

  /// NEW: Standardized search endpoint for material indents
  Future<PaginatedResponse<MaterialIndent>> searchMaterialIndents({
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

    final response = await _apiService.get('/api/material-indents',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<MaterialIndent>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, MaterialIndent.fromJson),
    );
  }

  /// NEW: Standardized search endpoint for vendor quotations
  Future<PaginatedResponse<VendorQuotation>> searchVendorQuotations({
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

    final response = await _apiService.get('/api/procurement/quotations/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<VendorQuotation>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, VendorQuotation.fromJson),
    );
  }
}
