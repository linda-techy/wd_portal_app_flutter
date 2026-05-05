import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/scheduling/data/services/project_schedule_config_service.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';

class ProjectScheduleConfigProvider extends ChangeNotifier {
  final int projectId;
  final ProjectScheduleConfigService _service;

  ProjectScheduleConfigProvider({
    required this.projectId,
    ProjectScheduleConfigService? service,
  }) : _service = service ?? ProjectScheduleConfigService();

  ProjectScheduleConfig? _config;
  List<ProjectHolidayOverride> _overrides = const [];
  bool _isLoading = false;
  String? _errorMessage;

  ProjectScheduleConfig? get config => _config;
  List<ProjectHolidayOverride> get overrides => List.unmodifiable(_overrides);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.get(projectId),
        _service.listOverrides(projectId),
      ]);
      _config = results[0] as ProjectScheduleConfig;
      _overrides = results[1] as List<ProjectHolidayOverride>;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(ProjectScheduleConfig next) async {
    try {
      _config = await _service.put(next);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addOverride({
    required int holidayId,
    required HolidayOverrideAction action,
  }) async {
    try {
      final ov = await _service.addOverride(
        projectId: projectId,
        holidayId: holidayId,
        action: action,
      );
      _overrides = [..._overrides, ov];
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOverride(int overrideId) async {
    try {
      await _service.deleteOverride(
          projectId: projectId, overrideId: overrideId);
      _overrides = _overrides.where((o) => o.id != overrideId).toList();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  String _humanize(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Not signed in. Please log in again.';
    }
    if (e.response?.statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Invalid request.';
    }
    return e.message ?? 'Network error.';
  }
}
