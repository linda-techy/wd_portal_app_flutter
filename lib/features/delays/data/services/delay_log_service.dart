import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:admin/services/api_service.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';

class DelayLogService {
  final ApiService _apiService = ApiService();

  Future<List<DelayLog>> getDelays(int projectId) async {
    final response = await _apiService.get('/api/projects/$projectId/delays');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DelayLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load delays');
    }
  }

  Future<DelayLog> logDelay(DelayLog delay) async {
    final response = await _apiService.post(
      '/api/projects/${delay.projectId}/delays',
      delay.toJson(),
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to log delay');
    }
  }

  Future<DelayLog> closeDelay(int projectId, int delayId, DateTime endDate) async {
    final response = await _apiService.put(
      '/api/projects/$projectId/delays/$delayId/close?endDate=${endDate.toIso8601String().substring(0, 10)}',
      {},
    );

    if (response.statusCode == 200) {
      return DelayLog.fromJson(json.decode(response.body));
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
