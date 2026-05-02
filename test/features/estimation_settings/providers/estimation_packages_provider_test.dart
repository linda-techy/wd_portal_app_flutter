import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late EstimationPackagesProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = EstimationPackagesProvider(
      service: EstimationPackageAdminService(dio: dio),
    );
  });

  test('load() populates packages and clears loading state', () async {
    adapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":"u1","internalName":"STANDARD","marketingName":"Signature","displayOrder":20,"active":true}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.load();
    expect(provider.packages, hasLength(1));
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('load() captures 403 as a friendly error message', () async {
    adapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Forbidden"}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.load();
    expect(provider.packages, isEmpty);
    expect(provider.errorMessage, contains('permission'));
  });

  test('setShowInactive(true) reloads with the new query param', () async {
    var calledWithIncludeInactive = false;
    adapter.mock('GET', '/api/estimation/packages', (options) {
      calledWithIncludeInactive = options.queryParameters['includeInactive'] == true;
      return ResponseBody.fromString(
        '{"success":true,"data":[]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.setShowInactive(true);
    expect(provider.showInactive, isTrue);
    expect(calledWithIncludeInactive, isTrue);
  });

  test('create() handles success:false 200 envelope (plain Exception path)', () async {
    adapter.mock('POST', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Internal name already taken"}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await provider.create(
      internalName: 'STANDARD',
      marketingName: 'Foo',
      displayOrder: 10,
    );
    expect(result, isNull);
    expect(provider.errorMessage, contains('Internal name already taken'));
  });

  test('delete() humanizes 404 as a friendly message', () async {
    adapter.mock('DELETE', '/api/estimation/packages/u1', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Not found"}',
        404,
        headers: {'content-type': ['application/json']},
      );
    });

    final ok = await provider.delete('u1');
    expect(ok, isFalse);
    expect(provider.errorMessage, contains('not found'));
  });
}
