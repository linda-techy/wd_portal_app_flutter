import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';
import '../../utils/error_handler.dart';

class BoqItem {
  final int id;
  final String description;
  final String unit;
  final double quantity;
  final double unitRate;
  final double? totalAmount;
  final String? notes;

  BoqItem({
    required this.id,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitRate,
    this.totalAmount,
    this.notes,
  });

  factory BoqItem.fromJson(Map<String, dynamic> json) {
    return BoqItem(
      id: json['id'],
      description: json['description'],
      unit: json['unit'],
      quantity: (json['quantity'] as num).toDouble(),
      unitRate: (json['unitRate'] as num).toDouble(),
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unitRate': unitRate,
      'notes': notes,
    };
  }
}

class BoqService {
  final ApiService _api = ApiService();

  Future<List<BoqItem>> getProjectBoq(int projectId) async {
    try {
      final response = await _api.dio.get('/boq/project/$projectId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => BoqItem.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load BoQ');
    } catch (e) {
      rethrow;
    }
  }

  Future<BoqItem> updateBoqItem(int id, BoqItem item) async {
    try {
      final response = await _api.dio.put(
        '/boq/$id',
        data: item.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return BoqItem.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update BoQ item');
    } catch (e) {
      rethrow;
    }
  }

  /// NEW: Standardized search endpoint for BOQ items
  Future<PaginatedResponse<BoqItem>> searchBoqItems({
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

    final response =
        await _api.get('/api/boq/search', queryParams: queryParams);
    return _api.unwrap<PaginatedResponse<BoqItem>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, BoqItem.fromJson),
    );
  }
}
