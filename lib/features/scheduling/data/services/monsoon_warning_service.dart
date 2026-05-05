import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';

class MonsoonWarningService {
  final Dio _dio;
  MonsoonWarningService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// GET /api/projects/{id}/schedule/warnings
  Future<List<MonsoonWarning>> warningsFor(int projectId) async {
    final response = await _dio.get('/api/projects/$projectId/schedule/warnings');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => MonsoonWarning.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
