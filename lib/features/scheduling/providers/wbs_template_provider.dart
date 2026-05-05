import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

class WbsTemplateProvider extends ChangeNotifier {
  final WbsTemplateService _service;

  WbsTemplateProvider({WbsTemplateService? service})
      : _service = service ?? WbsTemplateService();

  /// All templates the server returned for the current `includeInactive`
  /// setting. The screen filters these client-side by [filterType].
  List<WbsTemplate> _allTemplates = const [];
  bool _isLoading = false;
  String? _errorMessage;
  WbsTemplate? _editing;
  WbsProjectType? _filterType;
  bool _includeInactive = false;

  /// Templates after the [filterType] client-side filter is applied.
  List<WbsTemplate> get templates => List.unmodifiable(
        _filterType == null
            ? _allTemplates
            : _allTemplates.where((t) => t.projectType == _filterType).toList(),
      );
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WbsTemplate? get editing => _editing;
  WbsProjectType? get filterType => _filterType;
  bool get includeInactive => _includeInactive;

  /// Fetches the unfiltered list from the server (per the real contract,
  /// only [includeInactive] is server-side; project-type filter is applied in
  /// the getter above).
  Future<void> loadList({
    WbsProjectType? projectType,
    bool? includeInactive,
  }) async {
    _filterType = projectType;
    if (includeInactive != null) _includeInactive = includeInactive;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allTemplates = await _service.list(includeInactive: _includeInactive);
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

  /// Toggle a template's `isActive` flag.
  ///
  /// The backend has no PATCH; we PUT the full DTO with the flag flipped.
  /// We GET the latest DTO first so we don't blow away changes someone else
  /// made while the list was on screen.
  Future<bool> setActive(int id, bool isActive) async {
    try {
      final current = await _service.get(id);
      final updated = await _service.update(
        id,
        current.copyWith(isActive: isActive),
      );
      final idx = _allTemplates.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _allTemplates = [..._allTemplates]..[idx] = updated;
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
      _allTemplates = _allTemplates.where((t) => t.id != id).toList();
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
