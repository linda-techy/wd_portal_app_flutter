import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';
import 'package:admin/features/lead_estimation/data/services/estimation_sub_resource_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _estimationId = 'est-1';
const _inclusionId = 'inc-1';

const _inclusionJson = '{"id":"$_inclusionId","estimationId":"$_estimationId",'
    '"label":"Foundation works","description":"All RCC foundation work",'
    '"displayOrder":1,"percentage":null}';

const _milestoneJson = '{"id":"ms-1","estimationId":"$_estimationId",'
    '"label":"50% on signing","description":null,'
    '"displayOrder":1,"percentage":50.0}';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late EstimationSubResourceService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = EstimationSubResourceService(dio: dio);
  });

  test('list parses inclusions and asserts displayOrder', () async {
    adapter.mock(
      'GET',
      '/api/lead-estimations/$_estimationId/inclusions',
      (_) => ResponseBody.fromString(
        '{"success":true,"data":[$_inclusionJson]}',
        200,
        headers: {'content-type': ['application/json']},
      ),
    );

    final list = await service.list(_estimationId, SubResourceType.inclusion);
    expect(list, hasLength(1));
    expect(list.first.label, 'Foundation works');
    expect(list.first.displayOrder, 1);
    expect(list.first.percentage, isNull);
  });

  test('create POSTs payload and returns model', () async {
    adapter.mock(
      'POST',
      '/api/lead-estimations/$_estimationId/inclusions',
      (options) {
        final body = options.data as Map<String, dynamic>;
        expect(body['label'], 'Foundation works');
        expect(body['displayOrder'], 1);
        return ResponseBody.fromString(
          '{"success":true,"data":$_inclusionJson}',
          201,
          headers: {'content-type': ['application/json']},
        );
      },
    );

    final payload = EstimationSubResource.createPayload(
      label: 'Foundation works',
      displayOrder: 1,
    );
    final created =
        await service.create(_estimationId, SubResourceType.inclusion, payload);
    expect(created.id, _inclusionId);
    expect(created.estimationId, _estimationId);
  });

  test('update PUTs payload and returns updated model', () async {
    adapter.mock(
      'PUT',
      '/api/lead-estimations/$_estimationId/inclusions/$_inclusionId',
      (options) {
        final body = options.data as Map<String, dynamic>;
        expect(body['label'], 'Updated label');
        return ResponseBody.fromString(
          '{"success":true,"data":{"id":"$_inclusionId","estimationId":"$_estimationId",'
          '"label":"Updated label","description":null,"displayOrder":1,"percentage":null}}',
          200,
          headers: {'content-type': ['application/json']},
        );
      },
    );

    final payload = EstimationSubResource.createPayload(label: 'Updated label');
    final updated = await service.update(
        _estimationId, SubResourceType.inclusion, _inclusionId, payload);
    expect(updated.label, 'Updated label');
  });

  test('delete sends DELETE for payment-milestone', () async {
    var called = false;
    adapter.mock(
      'DELETE',
      '/api/lead-estimations/$_estimationId/payment-milestones/ms-1',
      (_) {
        called = true;
        return ResponseBody.fromString(
          '{"success":true,"message":"Deleted"}',
          200,
          headers: {'content-type': ['application/json']},
        );
      },
    );

    await service.delete(_estimationId, SubResourceType.paymentMilestone, 'ms-1');
    expect(called, isTrue);
  });

  test('list parses payment-milestone percentage', () async {
    adapter.mock(
      'GET',
      '/api/lead-estimations/$_estimationId/payment-milestones',
      (_) => ResponseBody.fromString(
        '{"success":true,"data":[$_milestoneJson]}',
        200,
        headers: {'content-type': ['application/json']},
      ),
    );

    final list =
        await service.list(_estimationId, SubResourceType.paymentMilestone);
    expect(list.first.percentage, 50.0);
    expect(list.first.label, '50% on signing');
  });
}
