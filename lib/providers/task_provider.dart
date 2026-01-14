import 'package:admin/models/task_models.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/providers/base_paginated_provider.dart';
import 'package:admin/services/task_service.dart';

class TaskProvider extends BasePaginatedProvider<TaskModel> {
  final TaskService _service = TaskService();

  @override
  Future<PaginatedResponse<TaskModel>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    return await _service.searchTasks(
      page: page,
      size: size,
      sortBy: sortBy,
      sortDirection: sortDirection,
      search: search,
      filters: filters,
    );
  }

  // Task-specific convenience methods

  void filterByPriority(String? priority) {
    updateFilter('priority', priority);
  }

  void filterByAssignedToId(int? assignedToId) {
    updateFilter('assignedToId', assignedToId);
  }

  void filterByProjectId(int? projectId) {
    updateFilter('projectId', projectId);
  }

  void filterByLeadId(int? leadId) {
    updateFilter('leadId', leadId);
  }

  void filterByCreatedById(int? createdById) {
    updateFilter('createdById', createdById);
  }

  void filterByDueDateRange(DateTime? minDueDate, DateTime? maxDueDate) {
    final updatedFilters = Map<String, dynamic>.from(filters);
    
    if (minDueDate == null) {
      updatedFilters.remove('minDueDate');
    } else {
      updatedFilters['minDueDate'] = minDueDate;
    }
    
    if (maxDueDate == null) {
      updatedFilters.remove('maxDueDate');
    } else {
      updatedFilters['maxDueDate'] = maxDueDate;
    }
    
    applyFilters(updatedFilters);
  }

  void applyAllFilters({
    String? priority,
    int? assignedToId,
    int? projectId,
    int? leadId,
    int? createdById,
    DateTime? minDueDate,
    DateTime? maxDueDate,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    final filters = <String, dynamic>{};
    
    if (priority != null) filters['priority'] = priority;
    if (assignedToId != null) filters['assignedToId'] = assignedToId;
    if (projectId != null) filters['projectId'] = projectId;
    if (leadId != null) filters['leadId'] = leadId;
    if (createdById != null) filters['createdById'] = createdById;
    if (minDueDate != null) filters['minDueDate'] = minDueDate;
    if (maxDueDate != null) filters['maxDueDate'] = maxDueDate;
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    if (status != null) filters['status'] = status;
    
    applyFilters(filters);
  }
}

