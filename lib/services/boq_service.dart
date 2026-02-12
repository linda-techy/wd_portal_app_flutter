import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';

class BoqWorkType {
  final int id;
  final String name;
  final String? description;
  final int? displayOrder;

  BoqWorkType({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder,
  });

  factory BoqWorkType.fromJson(Map<String, dynamic> json) {
    return BoqWorkType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      displayOrder: json['displayOrder'],
    );
  }
}

class BoqItem {
  final int id;
  final String description;
  final String unit;
  final double quantity;
  final double unitRate;
  final double? totalAmount;
  final String? notes;
  final int? projectId;
  final int? workTypeId;
  final String? workTypeName;

  BoqItem({
    required this.id,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitRate,
    this.totalAmount,
    this.notes,
    this.projectId,
    this.workTypeId,
    this.workTypeName,
  });

  factory BoqItem.fromJson(Map<String, dynamic> json) {
    return BoqItem(
      id: json['id'],
      description: json['description'] ?? '',
      unit: json['unit'] ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 0,
      unitRate: json['unitRate'] != null ? (json['unitRate'] as num).toDouble() : 0,
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      notes: json['notes'],
      projectId: json['project'] is Map ? json['project']['id'] : json['projectId'],
      workTypeId: json['workType'] is Map ? json['workType']['id'] : json['workTypeId'],
      workTypeName: json['workType'] is Map ? json['workType']['name'] : json['workTypeName'],
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

class BoqSummary {
  final int projectId;
  final int totalItems;
  final double totalAmount;
  final List<WorkTypeBreakdown> workTypeBreakdown;

  BoqSummary({
    required this.projectId,
    required this.totalItems,
    required this.totalAmount,
    required this.workTypeBreakdown,
  });

  factory BoqSummary.fromJson(Map<String, dynamic> json) {
    return BoqSummary(
      projectId: json['projectId'],
      totalItems: json['totalItems'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      workTypeBreakdown: (json['workTypeBreakdown'] as List? ?? [])
          .map((e) => WorkTypeBreakdown.fromJson(e))
          .toList(),
    );
  }
}

class WorkTypeBreakdown {
  final String workType;
  final double total;

  WorkTypeBreakdown({required this.workType, required this.total});

  factory WorkTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return WorkTypeBreakdown(
      workType: json['workType'],
      total: (json['total'] as num).toDouble(),
    );
  }
}

class BoqService {
  final ApiService _api = ApiService();

  Future<List<BoqItem>> getProjectBoq(int projectId) async {
    try {
      final response = await _api.dio.get('/api/boq/project/$projectId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => BoqItem.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load BoQ');
    } catch (e) {
      rethrow;
    }
  }

  Future<BoqItem> createBoqItem({
    required int projectId,
    required String description,
    required String unit,
    required double quantity,
    required double unitRate,
    int? workTypeId,
    String? notes,
  }) async {
    final response = await _api.dio.post('/api/boq', data: {
      'projectId': projectId,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'unitRate': unitRate,
      'workTypeId': workTypeId,
      'notes': notes,
    });
    if (response.statusCode == 201 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to create BoQ item');
  }

  Future<BoqItem> updateBoqItem(int id, Map<String, dynamic> data) async {
    final response = await _api.dio.put('/api/boq/$id', data: data);
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to update BoQ item');
  }

  Future<void> deleteBoqItem(int id) async {
    final response = await _api.dio.delete('/api/boq/$id');
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete BoQ item');
    }
  }

  Future<List<BoqWorkType>> getWorkTypes() async {
    final response = await _api.dio.get('/api/boq/work-types');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BoqWorkType.fromJson(e)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load work types');
  }

  Future<BoqSummary> getProjectSummary(int projectId) async {
    final response = await _api.dio.get('/boq/project/$projectId/summary');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqSummary.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load BoQ summary');
  }

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
