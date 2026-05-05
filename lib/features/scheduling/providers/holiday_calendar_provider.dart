import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/scheduling/data/services/holiday_admin_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';

class HolidayCalendarProvider extends ChangeNotifier {
  final HolidayAdminService _service;
  HolidayCalendarProvider({HolidayAdminService? service})
      : _service = service ?? HolidayAdminService();

  /// Cached server result for the last fetched (year, scope). The screen
  /// filters this list further by [scopeRef] client-side so we don't refetch
  /// when the user only narrows the state/district hint.
  List<Holiday> _all = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _year = DateTime.now().year;
  // Real backend requires a scope (no "All scopes" option). We default to
  // NATIONAL — admins can switch via the dropdown.
  HolidayScope _scope = HolidayScope.national;
  String? _scopeRef;

  /// Holidays after the optional client-side [scopeRef] narrow.
  List<Holiday> get holidays => List.unmodifiable(
        _scopeRef == null || _scopeRef!.isEmpty
            ? _all
            : _all.where((h) => h.scopeRef == _scopeRef).toList(),
      );
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get year => _year;
  HolidayScope get scope => _scope;
  String? get scopeRef => _scopeRef;

  /// Updates the year filter. Caller must `await load()` after to refetch.
  void setYear(int y) {
    if (y == _year) return;
    _year = y;
    notifyListeners();
  }

  /// Sets the scope (required) and optional in-scope reference. The reference
  /// is filtered client-side so changing it does not trigger a network call.
  void setScope(HolidayScope s, {String? scopeRef}) {
    _scope = s;
    _scopeRef = scopeRef;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _all = await _service.list(year: _year, scope: _scope);
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Holiday h) async {
    try {
      await _service.create(h);
      await load();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> patch(int id, Map<String, dynamic> changes) async {
    try {
      await _service.patch(id, changes);
      await load();
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
      await load();
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
