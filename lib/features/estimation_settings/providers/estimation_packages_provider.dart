import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';

class EstimationPackagesProvider extends ChangeNotifier {
  final EstimationPackageAdminService _service;

  EstimationPackagesProvider({EstimationPackageAdminService? service})
      : _service = service ?? EstimationPackageAdminService();

  List<EstimationPackage> _packages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showInactive = false;

  List<EstimationPackage> get packages => List.unmodifiable(_packages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showInactive => _showInactive;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _packages = await _service.list(includeInactive: _showInactive);
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setShowInactive(bool value) async {
    if (_showInactive == value) return;
    _showInactive = value;
    await load();
  }

  Future<EstimationPackage?> create({
    required String internalName,
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
  }) async {
    try {
      final created = await _service.create(
        internalName: internalName,
        marketingName: marketingName,
        tagline: tagline,
        description: description,
        displayOrder: displayOrder,
      );
      await load();
      return created;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    }
  }

  Future<EstimationPackage?> update(
    String id, {
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
    required bool active,
  }) async {
    try {
      final updated = await _service.update(
        id,
        marketingName: marketingName,
        tagline: tagline,
        description: description,
        displayOrder: displayOrder,
        active: active,
      );
      await load();
      return updated;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      await load();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return false;
    }
  }

  String _humanizeDioError(DioException e) {
    if (e.response?.statusCode == 401) return 'Not signed in. Please log in again.';
    if (e.response?.statusCode == 403) return 'You do not have permission to perform this action.';
    if (e.response?.statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Invalid request.';
    }
    return e.message ?? 'Network error.';
  }
}
