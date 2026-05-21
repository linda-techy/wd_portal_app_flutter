import 'package:admin/services/api_service.dart';
import 'package:admin/models/task_quality_gate.dart';

class TaskQualityGateService {
  final ApiService _api = ApiService();

  Future<List<TaskQualityGate>> listGates(int taskId) async {
    final resp = await _api.get('/api/tasks/$taskId/quality-gates');
    final raw = resp.data is Map<String, dynamic>
        ? resp.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = raw['data'] as List? ?? const [];
    return data
        .map((e) => TaskQualityGate.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  /// Sign off a gate. [status] is one of PASSED / FAILED / NA.
  /// When [status] is FAILED, [failureReason] is required.
  Future<TaskQualityGate> signOff(
    int taskId, {
    required String gateType,
    required String status,
    String? notes,
    String? failureReason,
  }) async {
    final body = <String, dynamic>{
      'gateType': gateType,
      'status': status,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (failureReason != null && failureReason.isNotEmpty)
        'failureReason': failureReason,
    };
    final resp = await _api.post(
      '/api/tasks/$taskId/quality-gates/sign-off',
      data: body,
    );
    final raw = resp.data is Map<String, dynamic>
        ? resp.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return TaskQualityGate.fromJson(data);
  }
}
