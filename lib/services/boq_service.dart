import 'dart:io';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

class BoqCategory {
  final int id;
  final int projectId;
  final int? parentId;
  final String? parentName;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final int itemCount;
  final DateTime? createdAt;

  BoqCategory({
    required this.id,
    required this.projectId,
    this.parentId,
    this.parentName,
    required this.name,
    this.description,
    required this.displayOrder,
    required this.isActive,
    required this.itemCount,
    this.createdAt,
  });

  factory BoqCategory.fromJson(Map<String, dynamic> json) {
    return BoqCategory(
      id: json['id'],
      projectId: json['projectId'],
      parentId: json['parentId'],
      parentName: json['parentName'],
      name: json['name'],
      description: json['description'],
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      itemCount: json['itemCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  bool get isTopLevel => parentId == null;
  bool get isSubcategory => parentId != null;
}

class InventoryMaterial {
  final int id;
  final String name;
  final String unit;
  final String? category;
  final bool isActive;

  InventoryMaterial({
    required this.id,
    required this.name,
    required this.unit,
    this.category,
    required this.isActive,
  });

  factory InventoryMaterial.fromJson(Map<String, dynamic> json) {
    return InventoryMaterial(
      id: json['id'],
      name: json['name'],
      unit: json['unit'] ?? '',
      category: json['category'],
      isActive: json['active'] ?? true,
    );
  }
}

class BoqItem {
  final int id;
  final int projectId;
  final String? projectName;
  final int? categoryId;
  final String? categoryName;
  final int? workTypeId;
  final String? workTypeName;
  final int? materialId;
  final String? materialName;
  final String? itemCode;
  final String description;
  final String unit;
  final double quantity;
  final double unitRate;
  final double totalAmount;
  final double executedQuantity;
  final double billedQuantity;
  final double remainingQuantity;
  final double remainingBillableQuantity;
  final double totalExecutedAmount;
  final double totalBilledAmount;
  final double costToComplete;
  final double executionPercentage;
  final double billingPercentage;
  final String status;
  final bool isActive;
  final String? specifications;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? version;
  // BASE | ADDON | OPTIONAL | EXCLUSION
  final String itemKind;

  BoqItem({
    required this.id,
    required this.projectId,
    this.projectName,
    this.categoryId,
    this.categoryName,
    this.workTypeId,
    this.workTypeName,
    this.materialId,
    this.materialName,
    this.itemCode,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitRate,
    required this.totalAmount,
    required this.executedQuantity,
    required this.billedQuantity,
    required this.remainingQuantity,
    required this.remainingBillableQuantity,
    required this.totalExecutedAmount,
    required this.totalBilledAmount,
    required this.costToComplete,
    required this.executionPercentage,
    required this.billingPercentage,
    required this.status,
    required this.isActive,
    this.specifications,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.version,
    this.itemKind = 'BASE',
  });

  factory BoqItem.fromJson(Map<String, dynamic> json) {
    return BoqItem(
      id: json['id'],
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      workTypeId: json['workTypeId'],
      workTypeName: json['workTypeName'],
      materialId: json['materialId'],
      materialName: json['materialName'],
      itemCode: json['itemCode'],
      description: json['description'] ?? '',
      unit: json['unit'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitRate: (json['unitRate'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      executedQuantity: (json['executedQuantity'] ?? 0).toDouble(),
      billedQuantity: (json['billedQuantity'] ?? 0).toDouble(),
      remainingQuantity: (json['remainingQuantity'] ?? 0).toDouble(),
      remainingBillableQuantity: (json['remainingBillableQuantity'] ?? 0).toDouble(),
      totalExecutedAmount: (json['totalExecutedAmount'] ?? 0).toDouble(),
      totalBilledAmount: (json['totalBilledAmount'] ?? 0).toDouble(),
      costToComplete: (json['costToComplete'] ?? 0).toDouble(),
      executionPercentage: (json['executionPercentage'] ?? 0).toDouble(),
      billingPercentage: (json['billingPercentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'DRAFT',
      isActive: json['isActive'] ?? true,
      specifications: json['specifications'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      version: json['version'],
      itemKind: json['itemKind'] ?? 'BASE',
    );
  }

  bool get isDraft => status == 'DRAFT';
  bool get isApproved => status == 'APPROVED';
  bool get isLocked => status == 'LOCKED';
  bool get isCompleted => status == 'COMPLETED';
  bool get canEdit => isDraft && isActive;
  bool get canDelete => isDraft && isActive;
  bool get canApprove => isDraft;
  bool get canLock => isApproved;
  bool get canExecute => isApproved || isLocked;
}

class BoqFinancialSummary {
  final int projectId;
  final String projectName;
  final int totalItems;
  final int activeItems;
  final double totalPlannedCost;
  final double totalExecutedCost;
  final double totalBilledCost;
  final double totalCostToComplete;
  final double overallExecutionPercentage;
  final double overallBillingPercentage;
  final List<CategoryFinancialBreakdown> categoryBreakdown;
  final List<WorkTypeFinancialBreakdown> workTypeBreakdown;

  BoqFinancialSummary({
    required this.projectId,
    required this.projectName,
    required this.totalItems,
    required this.activeItems,
    required this.totalPlannedCost,
    required this.totalExecutedCost,
    required this.totalBilledCost,
    required this.totalCostToComplete,
    required this.overallExecutionPercentage,
    required this.overallBillingPercentage,
    required this.categoryBreakdown,
    required this.workTypeBreakdown,
  });

  factory BoqFinancialSummary.fromJson(Map<String, dynamic> json) {
    return BoqFinancialSummary(
      projectId: json['projectId'],
      projectName: json['projectName'] ?? '',
      totalItems: json['totalItems'] ?? 0,
      activeItems: json['activeItems'] ?? 0,
      totalPlannedCost: (json['totalPlannedCost'] ?? 0).toDouble(),
      totalExecutedCost: (json['totalExecutedCost'] ?? 0).toDouble(),
      totalBilledCost: (json['totalBilledCost'] ?? 0).toDouble(),
      totalCostToComplete: (json['totalCostToComplete'] ?? 0).toDouble(),
      overallExecutionPercentage: (json['overallExecutionPercentage'] ?? 0).toDouble(),
      overallBillingPercentage: (json['overallBillingPercentage'] ?? 0).toDouble(),
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((e) => CategoryFinancialBreakdown.fromJson(e))
          .toList(),
      workTypeBreakdown: (json['workTypeBreakdown'] as List? ?? [])
          .map((e) => WorkTypeFinancialBreakdown.fromJson(e))
          .toList(),
    );
  }
}

class CategoryFinancialBreakdown {
  final int categoryId;
  final String categoryName;
  final int itemCount;
  final double plannedCost;
  final double executedCost;
  final double billedCost;
  final double costToComplete;

  CategoryFinancialBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.itemCount,
    required this.plannedCost,
    required this.executedCost,
    required this.billedCost,
    required this.costToComplete,
  });

  factory CategoryFinancialBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryFinancialBreakdown(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? '',
      itemCount: json['itemCount'] ?? 0,
      plannedCost: (json['plannedCost'] ?? 0).toDouble(),
      executedCost: (json['executedCost'] ?? 0).toDouble(),
      billedCost: (json['billedCost'] ?? 0).toDouble(),
      costToComplete: (json['costToComplete'] ?? 0).toDouble(),
    );
  }
}

class WorkTypeFinancialBreakdown {
  final int workTypeId;
  final String workTypeName;
  final int itemCount;
  final double plannedCost;
  final double executedCost;
  final double billedCost;
  final double costToComplete;

  WorkTypeFinancialBreakdown({
    required this.workTypeId,
    required this.workTypeName,
    required this.itemCount,
    required this.plannedCost,
    required this.executedCost,
    required this.billedCost,
    required this.costToComplete,
  });

  factory WorkTypeFinancialBreakdown.fromJson(Map<String, dynamic> json) {
    return WorkTypeFinancialBreakdown(
      workTypeId: json['workTypeId'],
      workTypeName: json['workTypeName'] ?? '',
      itemCount: json['itemCount'] ?? 0,
      plannedCost: (json['plannedCost'] ?? 0).toDouble(),
      executedCost: (json['executedCost'] ?? 0).toDouble(),
      billedCost: (json['billedCost'] ?? 0).toDouble(),
      costToComplete: (json['costToComplete'] ?? 0).toDouble(),
    );
  }
}

class BoqService {
  final ApiService _api = ApiService();

  // ---- CRUD Operations ----

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

  Future<BoqItem> getBoqItem(int id) async {
    final response = await _api.dio.get('/api/boq/$id');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load BoQ item');
  }

  Future<BoqItem> createBoqItem({
    required int projectId,
    int? categoryId,
    int? workTypeId,
    String? itemCode,
    required String description,
    required String unit,
    required double quantity,
    required double unitRate,
    int? materialId,
    String? specifications,
    String? notes,
    String itemKind = 'BASE',
  }) async {
    final response = await _api.dio.post('/api/boq', data: {
      'projectId': projectId,
      'categoryId': categoryId,
      'workTypeId': workTypeId,
      'itemCode': itemCode,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'unitRate': unitRate,
      'materialId': materialId,
      'specifications': specifications,
      'notes': notes,
      'itemKind': itemKind,
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

  // ---- Status Workflow ----

  Future<BoqItem> approveBoqItem(int id) async {
    final response = await _api.dio.patch('/api/boq/$id/approve');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to approve BoQ item');
  }

  Future<BoqItem> lockBoqItem(int id) async {
    final response = await _api.dio.patch('/api/boq/$id/lock');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to lock BoQ item');
  }

  Future<BoqItem> markAsCompleted(int id) async {
    final response = await _api.dio.patch('/api/boq/$id/complete');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to mark as completed');
  }

  // ---- Execution & Billing ----

  Future<BoqItem> recordExecution(int id, double quantity, {String? reference, String? notes}) async {
    final response = await _api.dio.patch('/api/boq/$id/execute', data: {
      'quantity': quantity,
      'reference': reference,
      'notes': notes,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to record execution');
  }

  Future<BoqItem> recordBilling(int id, double quantity, {String? reference, String? notes}) async {
    final response = await _api.dio.patch('/api/boq/$id/bill', data: {
      'quantity': quantity,
      'reference': reference,
      'notes': notes,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqItem.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to record billing');
  }

  // ---- Queries ----

  Future<BoqFinancialSummary> getFinancialSummary(int projectId) async {
    final response = await _api.dio.get('/api/boq/project/$projectId/financial-summary');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return BoqFinancialSummary.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load financial summary');
  }

  Future<List<BoqWorkType>> getWorkTypes() async {
    final response = await _api.dio.get('/api/boq/work-types');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BoqWorkType.fromJson(e)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load work types');
  }

  Future<List<InventoryMaterial>> getMaterials() async {
    try {
      final response = await _api.dio.get('/api/inventory/materials');
      if (response.statusCode == 200) {
        // Handle both wrapped response {success: true, data: [...]} and direct list [...]
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        return data.map((e) => InventoryMaterial.fromJson(e)).where((m) => m.isActive).toList();
      }
      return [];
    } catch (e) {
      // Gracefully handle if materials endpoint is not available
      debugPrint('Failed to load materials: $e');
      return [];
    }
  }

  // ---- Category Management ----

  Future<List<BoqCategory>> getCategories(int projectId) async {
    final response = await _api.dio.get('/api/boq/project/$projectId/categories');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => BoqCategory.fromJson(e)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load categories');
  }

  Future<BoqCategory> createCategory({
    required int projectId,
    int? parentId,
    required String name,
    String? description,
    int? displayOrder,
  }) async {
    final response = await _api.dio.post('/api/boq/categories', data: {
      'projectId': projectId,
      'parentId': parentId,
      'name': name,
      'description': description,
      'displayOrder': displayOrder,
    });
    if (response.statusCode == 201 && response.data['success'] == true) {
      return BoqCategory.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to create category');
  }

  Future<void> deleteCategory(int categoryId) async {
    final response = await _api.dio.delete('/api/boq/categories/$categoryId');
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete category');
    }
  }

  // ---- Search ----

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

    final response = await _api.get('/api/boq/search', queryParams: queryParams);
    return _api.unwrap<PaginatedResponse<BoqItem>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, BoqItem.fromJson),
    );
  }

  /// Downloads the BOQ Excel export for [projectId] and returns the local [File].
  Future<File> downloadBoqExcel(int projectId) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/boq_project_${projectId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    await _api.dio.download(
      '/api/boq/project/$projectId/export',
      filePath,
      options: Options(responseType: ResponseType.bytes),
    );

    return File(filePath);
  }
}
