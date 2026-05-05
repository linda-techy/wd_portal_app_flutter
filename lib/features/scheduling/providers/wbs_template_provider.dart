import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

class WbsTemplateProvider extends ChangeNotifier {
  final WbsTemplateService _service;

  WbsTemplateProvider({WbsTemplateService? service})
      : _service = service ?? WbsTemplateService();

  List<WbsTemplate> _templates = const [];
  bool _isLoading = false;
  String? _errorMessage;
  WbsTemplate? _editing;
  WbsProjectType? _filterType;

  List<WbsTemplate> get templates => List.unmodifiable(_templates);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WbsTemplate? get editing => _editing;
  WbsProjectType? get filterType => _filterType;

  Future<void> loadList({WbsProjectType? projectType}) async {
    _filterType = projectType;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _templates = await _service.list(projectType: projectType);
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEditing(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _editing = await _service.get(id);
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startNewDraft(WbsProjectType type) {
    _editing = WbsTemplate(
      code: type.toApi(),
      projectType: type,
      name: '${type.label} (draft)',
      version: 1,
      isActive: false,
      phases: const [],
    );
    notifyListeners();
  }

  void updateEditing(WbsTemplate next) {
    _editing = next;
    notifyListeners();
  }

  /// POST a new version of the editing draft. Returns true on success.
  Future<bool> saveEditing() async {
    if (_editing == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final saved = await _service.createNewVersion(_editing!);
      _editing = saved;
      // Refresh list in background
      // ignore: discarded_futures
      loadList(projectType: _filterType);
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setActive(int id, bool isActive) async {
    try {
      final updated = await _service.setActive(id, isActive);
      final idx = _templates.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _templates = [..._templates]..[idx] = updated;
        notifyListeners();
      }
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      _templates = _templates.where((t) => t.id != id).toList();
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
