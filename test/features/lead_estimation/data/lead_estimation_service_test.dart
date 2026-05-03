import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/data/services/lead_estimation_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _detailJson = '{"id":"e1","estimationNo":"EST-202605-ABC123","leadId":42,'
    '"projectType":"NEW_BUILD","packageId":"pkg-1","rateVersionId":"rv-1",'
    '"marketIndexId":"mi-1","status":"DRAFT","subtotal":2467500.00,'
    '"discountAmount":0.00,"gstAmount":444150.00,"grandTotal":2911650.00,'
    '"validUntil":"2026-06-01","createdAt":"2026-05-02T10:00:00",'
    '"publicViewToken":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",'
    '"lineItems":[{"lineType":"BASE","description":"Base package","amount":2467500,'
    '"displayOrder":1}]}';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late LeadEstimationService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = LeadEstimationService(dio: dio);
  });

  test('create POSTs the expected envelope and returns the detail', () async {
    adapter.mock('POST', '/api/lead-estimations', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['leadId'], 42);
      expect(body['preview'], isA<Map>());
      expect(body['preview']['projectType'], 'NEW_BUILD');
      expect(body.containsKey('validUntil'), isFalse);
      return ResponseBody.fromString(
        '{"success":true,"data":$_detailJson}', 201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await service.create(
      leadId: 42,
      previewPayload: {
        'projectType': 'NEW_BUILD',
        'packageId': 'pkg-1',
        'dimensions': {'floors': [{'floorName':'Ground','length':30,'width':35}],
                       'semiCoveredArea': 0, 'openTerraceArea': 0},
        'customisations': [],
        'siteFees': [],
        'addOns': [],
        'govtFees': [],
      },
    );
    expect(created.id, 'e1');
    expect(created.estimationNo, 'EST-202605-ABC123');
    expect(created.lineItems, hasLength(1));
  });

  test('listByLead parses summary rows', () async {
    adapter.mock('GET', '/api/lead-estimations', (options) {
      expect(options.queryParameters['leadId'], 42);
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"e1","estimationNo":"EST-202605-ABC123","leadId":42,
            "projectType":"NEW_BUILD","packageId":"pkg-1","status":"DRAFT",
            "grandTotal":2911650.0,"validUntil":"2026-06-01",
            "createdAt":"2026-05-02T10:00:00"}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final list = await service.listByLead(42);
    expect(list, hasLength(1));
    expect(list.first.estimationNo, 'EST-202605-ABC123');
    expect(list.first.status, LeadEstimationStatus.DRAFT);
  });

  test('get returns full detail with line items', () async {
    adapter.mock('GET', '/api/lead-estimations/e1', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":$_detailJson}', 200,
        headers: {'content-type': ['application/json']},
      );
    });
    final detail = await service.get('e1');
    expect(detail.lineItems.first.amount, 2467500);
  });

  test('delete sends DELETE and unwraps void', () async {
    var called = false;
    adapter.mock('DELETE', '/api/lead-estimations/e1', (_) {
      called = true;
      return ResponseBody.fromString(
        '{"success":true,"message":"Estimation deleted"}', 200,
        headers: {'content-type': ['application/json']},
      );
    });
    await service.delete('e1');
    expect(called, isTrue);
  });
}
