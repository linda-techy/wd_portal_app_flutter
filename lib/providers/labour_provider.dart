import 'package:flutter/foundation.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/labour_models.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/labour_service.dart';

class LabourProvider extends BasePaginatedProvider<Labour> {
  final LabourService _service = LabourService();

  @override
  Future<PaginatedResponse<Labour>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchLabour(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Labour-specific convenience methods

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByWorkerId(int? workerId) {
    updateFilter('workerId', workerId);
  }

  void filterByContractorName(String? contractorName) {
    updateFilter('contractorName', contractorName);
  }

  void filterByRole(String? role) {
    updateFilter('role', role);
  }

  void filterByEmploymentType(String? employmentType) {
    updateFilter('employmentType', employmentType);
  }

  void applyAllFilters({
    int? projectId,
    int? workerId,
    String? contractorName,
    String? role,
    String? employmentType,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};

    if (projectId != null) filters['projectId'] = projectId;
    if (workerId != null) filters['workerId'] = workerId;
    if (contractorName != null) filters['contractorName'] = contractorName;
    if (role != null) filters['role'] = role;
    if (employmentType != null) filters['employmentType'] = employmentType;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;

    applyFilters(filters);
  }

  // MB Entry methods
  List<MeasurementBook> _mbEntries = [];
  bool _isLoadingMB = false;

  List<MeasurementBook> get mbEntries => _mbEntries;
  bool get isLoadingMB => _isLoadingMB;

  Future<void> fetchMBEntries(int projectId) async {
    _isLoadingMB = true;
    notifyListeners();
    try {
      _mbEntries = await _service.getMBEntries(projectId);
    } catch (e) {
      debugPrint('Error fetching MB entries: $e');
    } finally {
      _isLoadingMB = false;
      notifyListeners();
    }
  }

  Future<bool> createMBEntry(MeasurementBook mb) async {
    try {
      await _service.createMBEntry(mb.toJson());
      return true;
    } catch (e) {
      debugPrint('Error creating MB entry: $e');
      return false;
    }
  }

  Future<bool> createLabour(Labour labour) async {
    try {
      await _service.createLabour(labour.toJson());
      await fetch(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error creating labour: $e');
      return false;
    }
  }
}
