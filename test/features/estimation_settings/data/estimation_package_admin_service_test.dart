import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late EstimationPackageAdminService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = EstimationPackageAdminService(dio: dio);
  });

  test('list parses ApiResponse envelope and returns models', () async {
    adapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '{"success":true,"message":"OK","data":[{"id":"u1","internalName":"STANDARD","marketingName":"Signature","displayOrder":20,"active":true}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.list();
    expect(result, hasLength(1));
    expect(result.first.marketingName, 'Signature');
    expect(result.first.active, isTrue);
  });

  test('create POSTs the right payload and returns the response model', () async {
    adapter.mock('POST', '/api/estimation/packages', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['internalName'], 'PREMIUM');
      expect(body['marketingName'], 'Luxe');
      expect(body['displayOrder'], 30);

      return ResponseBody.fromString(
        '{"success":true,"message":"Package created","data":{"id":"u2","internalName":"PREMIUM","marketingName":"Luxe","displayOrder":30,"active":true}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await service.create(
      internalName: 'PREMIUM',
      marketingName: 'Luxe',
      displayOrder: 30,
    );
    expect(created.id, 'u2');
    expect(created.internalName, 'PREMIUM');
  });

  test('update PUTs without internalName field', () async {
    adapter.mock('PUT', '/api/estimation/packages/u1', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body.containsKey('internalName'), isFalse,
          reason: 'internalName must NOT be in update payload (immutable)');
      expect(body['marketingName'], 'Signature Plus');

      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"u1","internalName":"STANDARD","marketingName":"Signature Plus","displayOrder":25,"active":true}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final updated = await service.update(
      'u1',
      marketingName: 'Signature Plus',
      displayOrder: 25,
      active: true,
    );
    expect(updated.marketingName, 'Signature Plus');
  });

  test('delete sends DELETE request', () async {
    var called = false;
    adapter.mock('DELETE', '/api/estimation/packages/u1', (_) {
      called = true;
      return ResponseBody.fromString(
        '{"success":true,"message":"Package deleted"}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await service.delete('u1');
    expect(called, isTrue);
  });
}
