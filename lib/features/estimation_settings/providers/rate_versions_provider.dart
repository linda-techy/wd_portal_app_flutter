import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/estimation_settings/data/services/package_rate_version_admin_service.dart';

class RateVersionsProvider extends ChangeNotifier {
  final PackageRateVersionAdminService _service;

  RateVersionsProvider({PackageRateVersionAdminService? service})
      : _service = service ?? PackageRateVersionAdminService();

  String? _packageId;
  ProjectType _projectType = ProjectType.NEW_BUILD;
  List<PackageRateVersion> _versions = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? get packageId => _packageId;
  ProjectType get projectType => _projectType;
  List<PackageRateVersion> get versions => List.unmodifiable(_versions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Update the (packageId, projectType) selection. Triggers [load] whenever
  /// `_packageId` is non-null after the change; otherwise just notifies listeners.
  Future<void> select({String? packageId, ProjectType? projectType}) async {
    bool changed = false;
    if (packageId != null && packageId != _packageId) {
      _packageId = packageId;
      changed = true;
    }
    if (projectType != null && projectType != _projectType) {
      _projectType = projectType;
      changed = true;
    }
    if (!changed) return;
    if (_packageId != null) {
      await load();
    } else {
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (_packageId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _versions = await _service.list(
        packageId: _packageId!,
        projectType: _projectType,
      );
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PackageRateVersion?> createNewVersion({
    required double materialRate,
    required double labourRate,
    required double overheadRate,
    DateTime? effectiveFrom,
  }) async {
    if (_packageId == null) {
      _errorMessage = 'Select a package first.';
      notifyListeners();
      return null;
    }
    try {
      final created = await _service.create(
        packageId: _packageId!,
        projectType: _projectType,
        materialRate: materialRate,
        labourRate: labourRate,
        overheadRate: overheadRate,
        effectiveFrom: effectiveFrom,
      );
      await load();
      return created;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  String _humanizeDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Not signed in. Please log in again.';
    if (status == 403) return 'You do not have permission to perform this action.';
    if (status == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Invalid request.';
    }
    if (status == 404) return 'Rate version not found.';
    if (status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Conflict — the operation could not be completed.';
    }
    if (status != null && status >= 500) return 'Server error. Please try again later.';
    return e.message ?? 'Network error.';
  }
}
