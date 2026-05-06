import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/scheduling/data/models/cpm_result_model.dart';
import 'package:admin/features/scheduling/data/services/cpm_service.dart';

/// Holds the latest CPM result for a single project.
///
/// Loaded lazily by `GanttScreen` via a post-frame callback. Failure is
/// non-fatal — the screen falls back to its existing plain-bar rendering
/// when [cpmByTaskId] is empty.
class GanttCpmProvider extends ChangeNotifier {
  final CpmService _service;

  GanttCpmProvider({CpmService? service}) : _service = service ?? CpmService();

  Map<int, CpmTaskResult> _cpmByTaskId = const {};
  DateTime? _projectStartDate;
  DateTime? _projectFinishDate;
  List<int> _criticalPathTaskIds = const [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<int, CpmTaskResult> get cpmByTaskId => Map.unmodifiable(_cpmByTaskId);
  DateTime? get projectStartDate => _projectStartDate;
  DateTime? get projectFinishDate => _projectFinishDate;
  List<int> get criticalPathTaskIds => List.unmodifiable(_criticalPathTaskIds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.fetch(projectId);
      _cpmByTaskId = result.byTaskId;
      _projectStartDate = result.projectStartDate;
      _projectFinishDate = result.projectFinishDate;
      _criticalPathTaskIds = result.criticalPathTaskIds;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      _cpmByTaskId = const {};
      _projectFinishDate = null;
      _projectStartDate = null;
      _criticalPathTaskIds = const [];
    } catch (e) {
      _errorMessage = e.toString();
      _cpmByTaskId = const {};
      _projectFinishDate = null;
      _projectStartDate = null;
      _criticalPathTaskIds = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _cpmByTaskId = const {};
    _projectStartDate = null;
    _projectFinishDate = null;
    _criticalPathTaskIds = const [];
    _errorMessage = null;
    notifyListeners();
  }

  String _humanize(DioException e) {
    final code = e.response?.statusCode;
    if (code == 404) return 'CPM not yet computed for this project.';
    if (code == 403) return 'You do not have permission to view CPM.';
    if (code == 401) return 'Authentication required.';
    return 'Failed to load CPM: ${e.message ?? 'unknown error'}';
  }
}
