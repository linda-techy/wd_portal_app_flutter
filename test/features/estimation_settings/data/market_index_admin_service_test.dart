import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/market_index_admin_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _v101SnapshotJson =
    '{"id":"33333333-3333-3333-3333-333333333301","snapshotDate":"2026-04-30",'
    '"steelRate":62.5,"cementRate":410.0,"sandRate":5800.0,"aggregateRate":1850.0,'
    '"tilesRate":38.0,"electricalRate":92.0,"paintsRate":285.0,'
    '"weights":{"steel":"0.30","cement":"0.20","sand":"0.12","aggregate":"0.08",'
    '"tiles":"0.12","electrical":"0.10","paints":"0.08"},'
    '"compositeIndex":1.0000,"active":true}';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late MarketIndexAdminService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = MarketIndexAdminService(dio: dio);
  });

  test('list parses ApiResponse envelope and decodes weights map + composite index', () async {
    adapter.mock('GET', '/api/estimation/market-index', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[$_v101SnapshotJson]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.list();
    expect(result, hasLength(1));
    expect(result.first.active, isTrue);
    expect(result.first.compositeIndex, 1.0000);
    expect(result.first.weightFor('steel'), 0.30);
    expect(result.first.steelRate, 62.5);
    expect(result.first.ratesByCommodity['cement'], 410.0);
  });

  test('getActive returns the open snapshot', () async {
    adapter.mock('GET', '/api/estimation/market-index/active', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":$_v101SnapshotJson}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final active = await service.getActive();
    expect(active, isNotNull);
    expect(active!.active, isTrue);
    expect(active.compositeIndex, 1.0000);
  });

  test('getActive returns null on 404', () async {
    adapter.mock('GET', '/api/estimation/market-index/active', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"No active market index snapshot"}',
        404,
        headers: {'content-type': ['application/json']},
      );
    });

    final active = await service.getActive();
    expect(active, isNull);
  });

  test('publish POSTs the right payload with stringified weights', () async {
    adapter.mock('POST', '/api/estimation/market-index', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['steelRate'], 65.0);
      expect(body['cementRate'], 415.0);
      // Weights serialized as Map<String, String>
      expect(body['weights'], isA<Map>());
      expect(double.parse(body['weights']['steel'] as String), closeTo(0.30, 0.0001));
      expect(double.parse(body['weights']['cement'] as String), closeTo(0.20, 0.0001));
      // snapshotDate omitted → backend defaults to today
      expect(body.containsKey('snapshotDate'), isFalse);

      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"v2","snapshotDate":"2026-05-02",'
        '"steelRate":65.0,"cementRate":415.0,"sandRate":5800.0,"aggregateRate":1850.0,'
        '"tilesRate":38.0,"electricalRate":92.0,"paintsRate":285.0,'
        '"weights":{"steel":"0.30","cement":"0.20","sand":"0.12","aggregate":"0.08",'
        '"tiles":"0.12","electrical":"0.10","paints":"0.08"},'
        '"compositeIndex":1.0156,"active":true}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await service.publish(
      steelRate: 65.0,
      cementRate: 415.0,
      sandRate: 5800.0,
      aggregateRate: 1850.0,
      tilesRate: 38.0,
      electricalRate: 92.0,
      paintsRate: 285.0,
      weights: const {
        'steel': 0.30, 'cement': 0.20, 'sand': 0.12, 'aggregate': 0.08,
        'tiles': 0.12, 'electrical': 0.10, 'paints': 0.08,
      },
    );
    expect(created.id, 'v2');
    expect(created.compositeIndex, 1.0156);
  });
}
