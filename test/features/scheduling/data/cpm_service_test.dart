import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/cpm_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late CpmService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = CpmService(dio: dio);
  });

  test('fetch hits /api/projects/{id}/cpm and parses raw body', () async {
    String? hitPath;
    adapter.mock('GET', '/api/projects/42/cpm', (options) {
      hitPath = options.path;
      return ResponseBody.fromString(
        '{'
        '"projectId":42,'
        '"projectStartDate":"2026-06-01",'
        '"projectFinishDate":"2026-09-30",'
        '"criticalTaskIds":[101],'
        '"tasks":['
        '{"taskId":101,"taskName":"Site Prep","durationDays":5,'
        '"esDate":"2026-06-01","efDate":"2026-06-05",'
        '"lsDate":"2026-06-01","lfDate":"2026-06-05",'
        '"totalFloatDays":0,"isCritical":true},'
        '{"taskId":102,"taskName":"Permit","durationDays":3,'
        '"esDate":"2026-06-01","efDate":"2026-06-03",'
        '"lsDate":"2026-06-04","lfDate":"2026-06-06",'
        '"totalFloatDays":3,"isCritical":false}'
        ']'
        '}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final result = await service.fetch(42);
    // Single /api/ prefix — no /api/api/...
    expect(hitPath, '/api/projects/42/cpm');
    expect(result.projectId, 42);
    expect(result.tasks.length, 2);
    expect(result.criticalPathTaskIds, contains(101));
    expect(result.tasks.first.isCritical, isTrue);
    expect(result.tasks.last.totalFloatDays, 3);
  });

  test('fetch surfaces DioException on 404', () async {
    adapter.mock('GET', '/api/projects/999/cpm', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Project not found"}',
        404,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    expect(() => service.fetch(999), throwsA(isA<DioException>()));
  });

  test('fetch surfaces DioException on 401', () async {
    adapter.mock('GET', '/api/projects/42/cpm', (_) {
      return ResponseBody.fromString(
        '{"message":"Unauthorized"}',
        401,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    expect(() => service.fetch(42), throwsA(isA<DioException>()));
  });
}
