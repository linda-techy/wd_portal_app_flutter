import 'package:admin/services/api_service.dart';
import 'package:admin/models/task_predecessor_edge.dart';

class TaskPredecessorService {
  final ApiService _api = ApiService();

  Future<List<TaskPredecessorEdge>> list(int taskId) async {
    final resp = await _api.get('/api/tasks/$taskId/predecessors');
    final raw = resp.data;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
    return list
        .map((e) => TaskPredecessorEdge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Replace-all semantics: the server deletes existing predecessors of [taskId]
  /// and inserts [entries]. Cycle detection is server-side; a [String] from a
  /// 400 response is the cycle/validation message.
  Future<List<TaskPredecessorEdge>> replace(
    int taskId,
    List<PredecessorEntry> entries,
  ) async {
    final resp = await _api.put(
      '/api/tasks/$taskId/predecessors',
      data: PredecessorListRequest(entries).toJson(),
    );
    // PUT returns the raw List<TaskPredecessor> entity which has slightly
    // different field shape than the DTO; just re-fetch via GET so the UI
    // gets predecessor titles consistently.
    if (resp.data is List) {
      return list(taskId);
    }
    return list(taskId);
  }
}
