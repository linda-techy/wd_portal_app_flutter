import 'package:admin/services/api_service.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';

class DelayLogService {
  final ApiService _apiService = ApiService();

  Future<List<DelayLog>> getDelays(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/delays');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => DelayLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load delays');
    }
  }

  Future<DelayLog> logDelay(DelayLog delay) async {
    final response = await _apiService.post(
      '/delay-logs',
      data: delay.toJson(),
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(response.data);
    } else {
      throw Exception('Failed to log delay');
    }
  }

  Future<DelayLog> closeDelay(int projectId, int delayId, DateTime endDate) async {
    final response = await _apiService.put(
      '/api/projects/$projectId/delays/$delayId/close?endDate=${endDate.toIso8601String().substring(0, 10)}',
      data: {},
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(response.data);
    } else {
      throw Exception('Failed to close delay');
    }
  }

  Future<void> deleteDelay(int projectId, int delayId) async {
    final response = await _apiService.delete('/api/projects/$projectId/delays/$delayId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete delay');
    }
  }
}
