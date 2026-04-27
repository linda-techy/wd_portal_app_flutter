import 'package:dio/dio.dart';

import 'package:admin/services/api_service.dart';
import 'package:admin/features/dpc_customization_catalog/data/models/dpc_customization_catalog_item.dart';

/// HTTP client for the DPC customization catalog endpoints.
///
/// Mirrors [QuotationCatalogService] but operates on DPC customization
/// rows (lump-sum amounts, no quantity).
class DpcCustomizationCatalogService {
  static final DpcCustomizationCatalogService _instance =
      DpcCustomizationCatalogService._internal();
  factory DpcCustomizationCatalogService() => _instance;
  DpcCustomizationCatalogService._internal();

  final ApiService _apiService = ApiService();

  // ---- Catalog CRUD ----

  Future<({List<DpcCustomizationCatalogItem> items, int totalElements, int totalPages})>
      search({
    String? search,
    String? category,
    bool? isActive,
    int page = 0,
    int size = 50,
    String sortBy = 'timesUsed',
    String sortDirection = 'desc',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (isActive != null) query['isActive'] = isActive;

    final response = await _apiService.get(
      '/api/dpc-customization-catalog',
      queryParams: query,
    );

    return _apiService.unwrap<
        ({
          List<DpcCustomizationCatalogItem> items,
          int totalElements,
          int totalPages,
        })>(response, (json) {
      Map<String, dynamic> page;
      if (json is Map<String, dynamic>) {
        page = json;
      } else {
        return (
          items: <DpcCustomizationCatalogItem>[],
          totalElements: 0,
          totalPages: 0,
        );
      }
      final content = (page['content'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DpcCustomizationCatalogItem.fromJson)
          .toList();
      final totalElements = (page['totalElements'] as num?)?.toInt() ?? 0;
      final totalPages = (page['totalPages'] as num?)?.toInt() ?? 0;
      return (
        items: content,
        totalElements: totalElements,
        totalPages: totalPages,
      );
    });
  }

  Future<DpcCustomizationCatalogItem> getById(int id) async {
    final response = await _apiService.get('/api/dpc-customization-catalog/$id');
    return _apiService.unwrap<DpcCustomizationCatalogItem>(
      response,
      (json) =>
          DpcCustomizationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DpcCustomizationCatalogItem> create({
    required String code,
    required String name,
    String? description,
    String? category,
    String? unit,
    required double defaultAmount,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'defaultAmount': defaultAmount,
    };
    final response =
        await _apiService.post('/api/dpc-customization-catalog', data: body);
    return _apiService.unwrap<DpcCustomizationCatalogItem>(
      response,
      (json) =>
          DpcCustomizationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DpcCustomizationCatalogItem> update(
    int id, {
    String? code,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? defaultAmount,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (unit != null) body['unit'] = unit;
    if (defaultAmount != null) body['defaultAmount'] = defaultAmount;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _apiService.dio.patch(
      '/api/dpc-customization-catalog/$id',
      data: body,
    );
    return _apiService.unwrap<DpcCustomizationCatalogItem>(
      response,
      (json) =>
          DpcCustomizationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteCatalogItem(int id) async {
    final response =
        await _apiService.delete('/api/dpc-customization-catalog/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // ---- DPC integration ----

  /// Append a new customization line to [dpcDocumentId] from a catalog row.
  /// Returns the raw line-item map (`{id, displayOrder, title, description,
  /// amount, source, boqItemId}`).
  Future<Map<String, dynamic>> addCustomizationFromCatalog({
    required int dpcDocumentId,
    required int catalogItemId,
    double? amountOverride,
  }) async {
    final body = <String, dynamic>{'catalogItemId': catalogItemId};
    if (amountOverride != null) body['amountOverride'] = amountOverride;

    final response = await _apiService.post(
      '/api/dpc-documents/$dpcDocumentId/customizations/from-catalog',
      data: body,
      options: Options(validateStatus: (s) => s != null && s < 400),
    );
    return _apiService.unwrap<Map<String, dynamic>>(
      response,
      (json) =>
          json is Map<String, dynamic> ? json : <String, dynamic>{},
    );
  }

  /// Promote an ad-hoc DPC customization line into the master catalog.
  Future<DpcCustomizationCatalogItem> promoteCustomizationToCatalog({
    required int lineId,
    String? code,
    required String name,
    String? category,
    String? unit,
    required double defaultAmount,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'category': category,
      'unit': unit,
      'defaultAmount': defaultAmount,
    };
    if (code != null && code.trim().isNotEmpty) body['code'] = code.trim();

    final response = await _apiService.post(
      '/api/dpc-documents/customizations/$lineId/promote-to-catalog',
      data: body,
    );
    return _apiService.unwrap<DpcCustomizationCatalogItem>(
      response,
      (json) =>
          DpcCustomizationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }
}
