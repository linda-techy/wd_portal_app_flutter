import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/estimation_settings/data/services/package_rate_version_admin_service.dart';

import '../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late PackageRateVersionAdminService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = PackageRateVersionAdminService(dio: dio);
  });

  test('list parses ApiResponse envelope and decodes ProjectType + nullable effectiveTo', () async {
    adapter.mock('GET', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"v1","packageId":"p1","projectType":"NEW_BUILD","materialRate":1500,"labourRate":550,"overheadRate":300,"effectiveFrom":"2026-04-01","effectiveTo":null},
          {"id":"v0","packageId":"p1","projectType":"NEW_BUILD","materialRate":1420,"labourRate":520,"overheadRate":280,"effectiveFrom":"2026-01-01","effectiveTo":"2026-03-31"}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.list(packageId: 'p1', projectType: ProjectType.NEW_BUILD);
    expect(result, hasLength(2));
    expect(result[0].isActive, isTrue);
    expect(result[0].totalRate, 2350);
    expect(result[1].isActive, isFalse);
    expect(result[1].effectiveTo!.toIso8601String().startsWith('2026-03-31'), isTrue);
  });

  test('getActive returns the open-ended row', () async {
    adapter.mock('GET', '/api/estimation/rate-versions/active', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"v1","packageId":"p1","projectType":"NEW_BUILD","materialRate":1500,"labourRate":550,"overheadRate":300,"effectiveFrom":"2026-04-01","effectiveTo":null}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final active = await service.getActive(packageId: 'p1', projectType: ProjectType.NEW_BUILD);
    expect(active, isNotNull);
    expect(active!.isActive, isTrue);
  });

  test('getActive returns null on 404 (no active version)', () async {
    adapter.mock('GET', '/api/estimation/rate-versions/active', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"No active rate version for given package + project type"}',
        404,
        headers: {'content-type': ['application/json']},
      );
    });

    final active = await service.getActive(packageId: 'p1', projectType: ProjectType.NEW_BUILD);
    expect(active, isNull);
  });

  test('create POSTs the right payload (uses ProjectType.name string) and returns the new version', () async {
    adapter.mock('POST', '/api/estimation/rate-versions', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['packageId'], 'p1');
      expect(body['projectType'], 'NEW_BUILD');
      expect(body['materialRate'], 1600);
      expect(body['labourRate'], 600);
      expect(body['overheadRate'], 320);
      // effectiveFrom omitted → backend defaults to today; payload should not include the key
      expect(body.containsKey('effectiveFrom'), isFalse);

      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"v2","packageId":"p1","projectType":"NEW_BUILD","materialRate":1600,"labourRate":600,"overheadRate":320,"effectiveFrom":"2026-05-01","effectiveTo":null}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await service.create(
      packageId: 'p1',
      projectType: ProjectType.NEW_BUILD,
      materialRate: 1600,
      labourRate: 600,
      overheadRate: 320,
    );
    expect(created.id, 'v2');
    expect(created.totalRate, 2520);
  });
}
