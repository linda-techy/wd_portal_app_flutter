import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';

/// Production-grade Task Service with RBAC support
/// Handles all task-related API calls with proper error handling
class TaskService {
  static const String baseUrl = 'http://localhost:8080/api/tasks';

  /// Get authorization token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all tasks (filtered by backend based on role)
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  /// Get task by ID
  Future<TaskModel> getTaskById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('You don\'t have permission to view this task');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found');
      } else {
        throw Exception('Failed to load task');
      }
    } catch (e) {
      throw Exception('Error fetching task: $e');
    }
  }

  /// Get my tasks (assigned to current user)
  Future<List<TaskModel>> getMyTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/my-tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my tasks');
      }
    } catch (e) {
      throw Exception('Error fetching my tasks: $e');
    }
  }

  /// Get tasks by project
  Future<List<TaskModel>> getTasksByProject(int projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/by-project/$projectId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load project tasks');
      }
    } catch (e) {
      throw Exception('Error fetching project tasks: $e');
    }
  }

  /// Get assignment history for a task
  Future<List<TaskAssignmentHistoryModel>> getAssignmentHistory(int taskId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$taskId/assignment-history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskAssignmentHistoryModel.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('You don\'t have permission to view assignment history');
      } else {
        throw Exception('Failed to load assignment history');
      }
    } catch (e) {
      throw Exception('Error fetching assignment history: $e');
    }
  }

  /// Create new task
  Future<TaskModel> createTask(CreateTaskRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('You don\'t have permission to create tasks');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create task');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  /// Update existing task
  /// RBAC is enforced at backend - will return 403 if unauthorized
  Future<TaskModel> updateTask(int id, UpdateTaskRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'You don\'t have permission to edit this task');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update task');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  /// Assign/reassign task
  /// Assignment history is automatically recorded at backend
  Future<TaskModel> assignTask(int taskId, int? userId, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$taskId/assign'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to assign task');
      }
    } catch (e) {
      throw Exception('Error assigning task: $e');
    }
  }

  /// Delete task
  /// RBAC is enforced at backend - will return 403 if unauthorized
  Future<void> deleteTask(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return; // Success - no content
      } else if (response.statusCode == 403) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'You don\'t have permission to delete this task');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete task');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  /// Get alert statistics
  Future<Map<String, dynamic>> getAlertStats({int days = 7}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/stats?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load alert stats');
      }
    } catch (e) {
      throw Exception('Error fetching alert stats: $e');
    }
  }

  /// Get recent alerts
  Future<List<TaskAlertModel>> getRecentAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/recent'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskAlertModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recent alerts');
      }
    } catch (e) {
      throw Exception('Error fetching recent alerts: $e');
    }
  }

  /// Trigger manual alerts (Admin only)
  Future<void> triggerManualAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/alerts/trigger'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        throw Exception('Failed to trigger alerts');
      }
    } catch (e) {
      throw Exception('Error triggering alerts: $e');
    }
  }
}
