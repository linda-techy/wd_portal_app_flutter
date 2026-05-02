import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/estimation_settings/data/models/market_index_snapshot.dart';

/// Admin API for /api/estimation/market-index.
///
/// Append-only: list/get/getActive/publish only — no update or delete.
/// Publishing a new snapshot deactivates the previous active row + computes
/// composite_index in one server-side transaction.
class MarketIndexAdminService {
  final ApiService _api;
  final Dio? _injectedDio;

  MarketIndexAdminService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/estimation/market-index
  Future<List<MarketIndexSnapshot>> list() async {
    final response = await _dio.get('/api/estimation/market-index');
    return _api.unwrapList(response, MarketIndexSnapshot.fromJson);
  }

  /// GET /api/estimation/market-index/{id}
  Future<MarketIndexSnapshot> get(String id) async {
    final response = await _dio.get('/api/estimation/market-index/$id');
    return _api.unwrap<MarketIndexSnapshot>(
      response,
      (json) => MarketIndexSnapshot.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/estimation/market-index/active
  /// Returns null on 404 (no active snapshot exists).
  Future<MarketIndexSnapshot?> getActive() async {
    try {
      final response = await _dio.get('/api/estimation/market-index/active');
      return _api.unwrap<MarketIndexSnapshot>(
        response,
        (json) => MarketIndexSnapshot.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/estimation/market-index
  /// Returns the newly-published snapshot with server-computed composite_index.
  Future<MarketIndexSnapshot> publish({
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
    final response = await _dio.post(
      '/api/estimation/market-index',
      data: MarketIndexSnapshot.createPayload(
        steelRate: steelRate,
        cementRate: cementRate,
        sandRate: sandRate,
        aggregateRate: aggregateRate,
        tilesRate: tilesRate,
        electricalRate: electricalRate,
        paintsRate: paintsRate,
        weights: weights,
        snapshotDate: snapshotDate,
      ),
    );
    return _api.unwrap<MarketIndexSnapshot>(
      response,
      (json) => MarketIndexSnapshot.fromJson(json as Map<String, dynamic>),
    );
  }
}
