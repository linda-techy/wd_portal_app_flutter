import 'package:http/http.dart' as http;
import '../models/task_models.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

/// Production-grade Task Service with RBAC support
/// Handles all task-related API calls with proper error handling
class TaskService {
  final ApiService _apiService = ApiService();

  /// Get all tasks (filtered by backend based on role)
  Future<List<TaskModel>> getAllTasks() async {
    final response = await _apiService.get('/api/tasks');
    return _apiService.unwrapList(response, (json) => TaskModel.fromJson(json));
  }

  /// Get task by ID
  Future<TaskModel> getTaskById(int id) async {
    final response = await _apiService.get('/api/tasks/$id');
    return _apiService.unwrap(
        response, (json) => TaskModel.fromJson(json as Map<String, dynamic>));
  }

  /// Get my tasks (assigned to current user)
  Future<List<TaskModel>> getMyTasks() async {
    final response = await _apiService.get('/api/tasks/my-tasks');
    return _apiService.unwrapList(response, (json) => TaskModel.fromJson(json));
  }

  /// Get tasks by project
  Future<List<TaskModel>> getTasksByProject(int projectId) async {
    final response = await _apiService.get('/api/tasks/by-project/$projectId');
    return _apiService.unwrapList(response, (json) => TaskModel.fromJson(json));
  }

  /// Get tasks by lead
  Future<List<TaskModel>> getTasksByLead(int leadId) async {
    final response = await _apiService.get('/api/tasks/by-lead/$leadId');
    return _apiService.unwrapList(response, (json) => TaskModel.fromJson(json));
  }

  /// Get assignment history for a task
  Future<List<TaskAssignmentHistoryModel>> getAssignmentHistory(
      int taskId) async {
    final response = await _apiService.get('/api/tasks/$taskId/assignment-history');
    return _apiService.unwrapList(
        response, (json) => TaskAssignmentHistoryModel.fromJson(json));
  }

  /// Create new task
  Future<TaskModel> createTask(CreateTaskRequest request) async {
    final response = await _apiService.post('/api/tasks', data: request.toJson());
    return _apiService.unwrap(
        response, (json) => TaskModel.fromJson(json as Map<String, dynamic>));
  }

  /// Update existing task
  /// RBAC is enforced at backend - will return 403 if unauthorized
  Future<TaskModel> updateTask(int id, UpdateTaskRequest request) async {
    final response =
        await _apiService.put('/api/tasks/$id', data: request.toJson());
    return _apiService.unwrap(
        response, (json) => TaskModel.fromJson(json as Map<String, dynamic>));
  }

  /// Assign/reassign task
  /// Assignment history is automatically recorded at backend
  Future<TaskModel> assignTask(int taskId, int? userId, {String? notes}) async {
    final response = await _apiService.put('/api/tasks/$taskId/assign', data: {
      'userId': userId,
      if (notes != null) 'notes': notes,
    });
    return _apiService.unwrap(
        response, (json) => TaskModel.fromJson(json as Map<String, dynamic>));
  }

  /// Delete task
  /// RBAC is enforced at backend - will return 403 if unauthorized
  Future<void> deleteTask(int id) async {
    final response = await _apiService.delete('/api/tasks/$id');
    _apiService.unwrap(response, (_) {});
  }

  /// Get alert statistics
  Future<Map<String, dynamic>> getAlertStats({int days = 7}) async {
    final response = await _apiService
        .get('/api/tasks/alerts/stats', queryParams: {'days': days.toString()});
    return _apiService.unwrap(response, (json) => json as Map<String, dynamic>);
  }

  /// Get recent alerts
  Future<List<TaskAlertModel>> getRecentAlerts() async {
    final response = await _apiService.get('/api/tasks/alerts/recent');
    return _apiService.unwrapList(
        response, (json) => TaskAlertModel.fromJson(json));
  }

  /// Trigger manual alerts (Admin only)
  Future<void> triggerAlerts() async {
    final response = await _apiService.post('/api/tasks/alerts/trigger', data: {});
    _apiService.unwrap(response, (_) {});
  }

  /// NEW: Standardized search endpoint for tasks
  Future<PaginatedResponse<TaskModel>> searchTasks({
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
        await _apiService.get('/api/tasks/search', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<TaskModel>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, TaskModel.fromJson),
    );
  }
}
