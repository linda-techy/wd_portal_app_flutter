import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_options.dart';
import 'package:admin/features/lead_estimation/data/services/estimation_options_service.dart';

/// Provides the estimation options catalog (customisation categories, add-ons,
/// site fees, government fees) for the lead-estimation wizard.
class EstimationOptionsProvider extends ChangeNotifier {
  final EstimationOptionsService _service;

  EstimationOptionsProvider({EstimationOptionsService? service})
      : _service = service ?? EstimationOptionsService();

  EstimationOptions? _options;
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedPackageId; // tracks the last packageId fetched

  EstimationOptions? get options => _options;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches the catalog for [packageId] (null = all packages).
  ///
  /// No-ops if the same [packageId] is already loaded and no error is present,
  /// so repeated wizard renders are cheap.
  Future<void> loadForPackage(String? packageId) async {
    if (!_isLoading &&
        _options != null &&
        _errorMessage == null &&
        _loadedPackageId == packageId) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _options = await _service.get(packageId: packageId);
      _loadedPackageId = packageId;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    if (status == 404) return 'Options not found.';
    if (status != null && status >= 500) return 'Server error. Please try again later.';
    return e.message ?? 'Network error.';
  }
}
