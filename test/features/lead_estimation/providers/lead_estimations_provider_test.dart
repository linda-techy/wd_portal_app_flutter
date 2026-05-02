import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/lead_estimation/data/services/lead_estimation_service.dart';
import 'package:admin/features/lead_estimation/providers/lead_estimations_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _summaryListJson =
    '{"success":true,"data":['
    '{"id":"e1","estimationNo":"EST-202605-ABC123","leadId":42,'
    '"projectType":"NEW_BUILD","packageId":"pkg-1","status":"DRAFT",'
    '"grandTotal":2911650.0,"validUntil":"2026-06-01",'
    '"createdAt":"2026-05-02T10:00:00"}'
    ']}';

const _detailJson =
    '{"id":"e2","estimationNo":"EST-202605-DEF456","leadId":42,'
    '"projectType":"NEW_BUILD","packageId":"pkg-1","rateVersionId":"rv-1",'
    '"marketIndexId":"mi-1","status":"DRAFT","subtotal":2467500.00,'
    '"discountAmount":0.00,"gstAmount":444150.00,"grandTotal":2911650.00,'
    '"validUntil":"2026-06-01","createdAt":"2026-05-02T10:00:00",'
    '"lineItems":[{"lineType":"BASE","description":"Base package","amount":2467500,'
    '"displayOrder":1}]}';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late LeadEstimationsProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = LeadEstimationsProvider(
      service: LeadEstimationService(dio: dio),
    );
  });

  test('loadForLead populates estimations and clears loading state', () async {
    adapter.mock('GET', '/api/lead-estimations', (options) {
      expect(options.queryParameters['leadId'], 42);
      return ResponseBody.fromString(
        _summaryListJson,
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.loadForLead(42);

    expect(provider.leadId, 42);
    expect(provider.estimations, hasLength(1));
    expect(provider.estimations.first.estimationNo, 'EST-202605-ABC123');
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('load 403 captures friendly error message', () async {
    adapter.mock('GET', '/api/lead-estimations', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Forbidden"}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.loadForLead(42);

    expect(provider.estimations, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, contains('permission'));
  });

  test('create success path triggers reload and returns the new detail', () async {
    var listCallCount = 0;
    adapter.mock('GET', '/api/lead-estimations', (_) {
      listCallCount++;
      return ResponseBody.fromString(
        _summaryListJson,
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('POST', '/api/lead-estimations', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":$_detailJson}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    // First load the lead so _leadId is set.
    await provider.loadForLead(42);
    expect(listCallCount, 1);

    final created = await provider.create(
      previewPayload: {
        'projectType': 'NEW_BUILD',
        'packageId': 'pkg-1',
        'dimensions': {
          'floors': [
            {'floorName': 'Ground', 'length': 30, 'width': 35}
          ],
          'semiCoveredArea': 0,
          'openTerraceArea': 0,
        },
        'customisations': [],
        'siteFees': [],
        'addOns': [],
        'govtFees': [],
      },
    );

    expect(created, isNotNull);
    expect(created!.id, 'e2');
    expect(created.estimationNo, 'EST-202605-DEF456');
    expect(listCallCount, 2, reason: 'create should trigger an automatic reload');
    expect(provider.estimations, hasLength(1));
  });
}
