import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/market_index_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/market_index_provider.dart';

import '../test_helpers/mock_dio_adapter.dart';

const _twoSnapshotsJson =
    '{"success":true,"data":['
    '{"id":"v1","snapshotDate":"2026-05-02","steelRate":65.0,"cementRate":415.0,'
    '"sandRate":5800.0,"aggregateRate":1850.0,"tilesRate":38.0,"electricalRate":92.0,'
    '"paintsRate":285.0,"weights":{"steel":"0.30","cement":"0.20","sand":"0.12",'
    '"aggregate":"0.08","tiles":"0.12","electrical":"0.10","paints":"0.08"},'
    '"compositeIndex":1.0156,"active":true},'
    '{"id":"v0","snapshotDate":"2026-04-30","steelRate":62.5,"cementRate":410.0,'
    '"sandRate":5800.0,"aggregateRate":1850.0,"tilesRate":38.0,"electricalRate":92.0,'
    '"paintsRate":285.0,"weights":{"steel":"0.30","cement":"0.20","sand":"0.12",'
    '"aggregate":"0.08","tiles":"0.12","electrical":"0.10","paints":"0.08"},'
    '"compositeIndex":1.0000,"active":false}'
    ']}';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late MarketIndexProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = MarketIndexProvider(
      service: MarketIndexAdminService(dio: dio),
    );
  });

  test('load() populates snapshots and clears loading state', () async {
    adapter.mock('GET', '/api/estimation/market-index', (_) {
      return ResponseBody.fromString(
        _twoSnapshotsJson, 200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.load();
    expect(provider.snapshots, hasLength(2));
    expect(provider.snapshots.first.active, isTrue);
    expect(provider.snapshots.first.compositeIndex, 1.0156);
    expect(provider.errorMessage, isNull);
  });

  test('load() captures 403 as friendly error', () async {
    adapter.mock('GET', '/api/estimation/market-index', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Forbidden"}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.load();
    expect(provider.snapshots, isEmpty);
    expect(provider.errorMessage, contains('permission'));
  });

  test('publish success path triggers reload and returns the new snapshot', () async {
    var listCallCount = 0;
    adapter.mock('GET', '/api/estimation/market-index', (_) {
      listCallCount++;
      return ResponseBody.fromString(
        _twoSnapshotsJson, 200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('POST', '/api/estimation/market-index', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"v1","snapshotDate":"2026-05-02",'
        '"steelRate":65.0,"cementRate":415.0,"sandRate":5800.0,"aggregateRate":1850.0,'
        '"tilesRate":38.0,"electricalRate":92.0,"paintsRate":285.0,'
        '"weights":{"steel":"0.30","cement":"0.20","sand":"0.12","aggregate":"0.08",'
        '"tiles":"0.12","electrical":"0.10","paints":"0.08"},'
        '"compositeIndex":1.0156,"active":true}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await provider.publish(
      steelRate: 65.0, cementRate: 415.0, sandRate: 5800.0, aggregateRate: 1850.0,
      tilesRate: 38.0, electricalRate: 92.0, paintsRate: 285.0,
      weights: const {
        'steel': 0.30, 'cement': 0.20, 'sand': 0.12, 'aggregate': 0.08,
        'tiles': 0.12, 'electrical': 0.10, 'paints': 0.08,
      },
    );
    expect(created, isNotNull);
    expect(created!.compositeIndex, 1.0156);
    expect(listCallCount, 1, reason: 'publish should trigger an automatic reload');
  });
}
