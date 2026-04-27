import 'package:dio/dio.dart';

import 'package:admin/services/api_service.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';

/// HTTP client for the quotation-catalog endpoints.
///
/// Uses the singleton [ApiService] / [ApiService.unwrap] like other modern
/// services in this codebase (mirrors [DpcService] style).
class QuotationCatalogService {
  static final QuotationCatalogService _instance =
      QuotationCatalogService._internal();
  factory QuotationCatalogService() => _instance;
  QuotationCatalogService._internal();

  final ApiService _apiService = ApiService();

  // ---- Catalog CRUD ----

  /// Search the master quotation-item catalog with paging + filters.
  ///
  /// Returns the parsed list together with paging metadata so the caller can
  /// drive pagination controls without re-issuing the request.
  Future<({List<QuotationCatalogItem> items, int totalElements, int totalPages})>
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
      '/api/quotation-catalog',
      queryParams: query,
    );

    return _apiService.unwrap<
        ({
          List<QuotationCatalogItem> items,
          int totalElements,
          int totalPages,
        })>(response, (json) {
      // Backend returns ApiResponse<Page<QuotationCatalogItemDto>>; ApiService
      // already unwrapped the outer ApiResponse, leaving us with the Page map.
      Map<String, dynamic> page;
      if (json is Map<String, dynamic>) {
        page = json;
      } else {
        return (
          items: <QuotationCatalogItem>[],
          totalElements: 0,
          totalPages: 0,
        );
      }
      final content = (page['content'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuotationCatalogItem.fromJson)
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

  Future<QuotationCatalogItem> getById(int id) async {
    final response = await _apiService.get('/api/quotation-catalog/$id');
    return _apiService.unwrap<QuotationCatalogItem>(
      response,
      (json) => QuotationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<QuotationCatalogItem> create({
    required String code,
    required String name,
    String? description,
    String? category,
    String? unit,
    required double defaultUnitPrice,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'defaultUnitPrice': defaultUnitPrice,
    };
    final response =
        await _apiService.post('/api/quotation-catalog', data: body);
    return _apiService.unwrap<QuotationCatalogItem>(
      response,
      (json) => QuotationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<QuotationCatalogItem> update(
    int id, {
    String? code,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? defaultUnitPrice,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (unit != null) body['unit'] = unit;
    if (defaultUnitPrice != null) body['defaultUnitPrice'] = defaultUnitPrice;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _apiService.dio.patch(
      '/api/quotation-catalog/$id',
      data: body,
    );
    return _apiService.unwrap<QuotationCatalogItem>(
      response,
      (json) => QuotationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteCatalogItem(int id) async {
    final response = await _apiService.delete('/api/quotation-catalog/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // ---- Quotation-line integration ----

  /// Append a new line item to [quotationId] sourced from a catalog row.
  ///
  /// Returns the raw line-item map exactly as the backend produced it
  /// (`{id, itemNumber, description, quantity, unitPrice, totalPrice,
  /// catalogItemId}`) so the caller can splice it into its in-memory list
  /// without an extra refresh round-trip.
  Future<Map<String, dynamic>> addItemFromCatalog({
    required int quotationId,
    required int catalogItemId,
    double? quantity,
    double? unitPriceOverride,
  }) async {
    final body = <String, dynamic>{'catalogItemId': catalogItemId};
    if (quantity != null) body['quantity'] = quantity;
    if (unitPriceOverride != null) body['unitPriceOverride'] = unitPriceOverride;

    final response = await _apiService.post(
      '/leads/quotations/$quotationId/items/from-catalog',
      data: body,
      options: Options(validateStatus: (s) => s != null && s < 400),
    );
    return _apiService.unwrap<Map<String, dynamic>>(
      response,
      (json) => json is Map<String, dynamic>
          ? json
          : <String, dynamic>{},
    );
  }

  /// Promote an ad-hoc quotation line item ([itemId]) into the master catalog.
  Future<QuotationCatalogItem> promoteItemToCatalog({
    required int itemId,
    required String code,
    required String name,
    String? category,
    String? unit,
    required double defaultUnitPrice,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'category': category,
      'unit': unit,
      'defaultUnitPrice': defaultUnitPrice,
    };
    final response = await _apiService.post(
      '/leads/quotations/items/$itemId/promote-to-catalog',
      data: body,
    );
    return _apiService.unwrap<QuotationCatalogItem>(
      response,
      (json) => QuotationCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }
}
