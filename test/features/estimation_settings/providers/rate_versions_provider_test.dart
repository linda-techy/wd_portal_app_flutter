import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/package_rate_version_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/rate_versions_provider.dart';

class _MockDioAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _handlers = {};
  void mock(String method, String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['$method $path'] = handler;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<dynamic>? cancelFuture) async {
    final handler = _handlers['${options.method} ${options.path}'];
    if (handler == null) throw StateError('No mock for ${options.method} ${options.path}');
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _MockDioAdapter adapter;
  late RateVersionsProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = _MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = RateVersionsProvider(
      service: PackageRateVersionAdminService(dio: dio),
    );
  });

  test('select(packageId) triggers load() and populates versions', () async {
    adapter.mock('GET', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":"v1","packageId":"p1","projectType":"NEW_BUILD","materialRate":1500,"labourRate":550,"overheadRate":300,"effectiveFrom":"2026-04-01","effectiveTo":null}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.select(packageId: 'p1');
    expect(provider.packageId, 'p1');
    expect(provider.versions, hasLength(1));
    expect(provider.errorMessage, isNull);
  });

  test('load() captures 403 as friendly error', () async {
    adapter.mock('GET', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Forbidden"}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.select(packageId: 'p1');
    expect(provider.versions, isEmpty);
    expect(provider.errorMessage, contains('permission'));
  });

  test('createNewVersion success path triggers reload and returns the new version', () async {
    var listCallCount = 0;
    adapter.mock('GET', '/api/estimation/rate-versions', (_) {
      listCallCount++;
      return ResponseBody.fromString(
        '{"success":true,"data":[]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('POST', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"v2","packageId":"p1","projectType":"NEW_BUILD","materialRate":1600,"labourRate":600,"overheadRate":320,"effectiveFrom":"2026-05-01","effectiveTo":null}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.select(packageId: 'p1');
    expect(listCallCount, 1);

    final created = await provider.createNewVersion(
      materialRate: 1600, labourRate: 600, overheadRate: 320,
    );
    expect(created, isNotNull);
    expect(created!.id, 'v2');
    expect(listCallCount, 2, reason: 'createNewVersion should trigger an automatic reload');
  });
}
