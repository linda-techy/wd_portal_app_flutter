import 'package:admin/models/task.dart';
import 'package:admin/services/api_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final ApiService _apiService = ApiService();

  // Get all tasks (admin sees all, employees see assigned tasks)
  Future<List<Task>> getAllTasks() async {
    try {
      final response = await _apiService.get('/tasks');
      final List<dynamic> data = response.data;
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get tasks assigned to the current user
  Future<List<Task>> getMyTasks() async {
    try {
      final response = await _apiService.get('/tasks/my-tasks');
      final List<dynamic> data = response.data;
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch my tasks: $e');
    }
  }

  // Get a single task by ID
  Future<Task> getTaskById(int id) async {
    try {
      final response = await _apiService.get('/tasks/$id');
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(String status) async {
    try {
      final response = await _apiService.get('/tasks/by-status/$status');
      final List<dynamic> data = response.data;
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  // Get tasks by project
  Future<List<Task>> getTasksByProject(int projectId) async {
    try {
      final response = await _apiService.get('/tasks/by-project/$projectId');
      final List<dynamic> data = response.data;
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by project: $e');
    }
  }

  // Create a new task (admin only)
  Future<Task> createTask(Task task) async {
    try {
      final response = await _apiService.post('/tasks', task.toJson());
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Update an existing task
  Future<Task> updateTask(int id, Task task) async {
    try {
      final response = await _apiService.put('/tasks/$id', task.toJson());
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Assign a task to a user (admin only)
  Future<Task> assignTask(int taskId, int userId) async {
    try {
      final response = await _apiService.put(
        '/tasks/$taskId/assign',
        {'userId': userId},
      );
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  // Delete a task (admin only)
  Future<void> deleteTask(int id) async {
    try {
      await _apiService.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
