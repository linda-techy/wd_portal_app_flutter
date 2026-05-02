import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/estimation_settings/data/models/market_index_snapshot.dart';
import 'package:admin/features/estimation_settings/data/services/market_index_admin_service.dart';

class MarketIndexProvider extends ChangeNotifier {
  final MarketIndexAdminService _service;

  MarketIndexProvider({MarketIndexAdminService? service})
      : _service = service ?? MarketIndexAdminService();

  List<MarketIndexSnapshot> _snapshots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MarketIndexSnapshot> get snapshots => List.unmodifiable(_snapshots);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshots = await _service.list();
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MarketIndexSnapshot?> publish({
    required double steelRate,
    required double cementRate,
    required double sandRate,
    required double aggregateRate,
    required double tilesRate,
    required double electricalRate,
    required double paintsRate,
    required Map<String, double> weights,
    DateTime? snapshotDate,
  }) async {
    try {
      final created = await _service.publish(
        steelRate: steelRate,
        cementRate: cementRate,
        sandRate: sandRate,
        aggregateRate: aggregateRate,
        tilesRate: tilesRate,
        electricalRate: electricalRate,
        paintsRate: paintsRate,
        weights: weights,
        snapshotDate: snapshotDate,
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
    if (status == 404) return 'Snapshot not found.';
    if (status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Conflict — the operation could not be completed.';
    }
    if (status != null && status >= 500) return 'Server error. Please try again later.';
    return e.message ?? 'Network error.';
  }
}
