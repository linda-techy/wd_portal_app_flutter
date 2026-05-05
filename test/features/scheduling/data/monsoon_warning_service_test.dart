import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/monsoon_warning_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late MonsoonWarningService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = MonsoonWarningService(dio: dio);
  });

  test('warningsFor returns parsed list (raw body)', () async {
    adapter.mock('GET', '/api/projects/42/schedule/warnings', (_) {
      return ResponseBody.fromString(
        '[{"taskId":7,"taskName":"Slab — Floor 1",'
        '"plannedStart":"2026-07-15","plannedEnd":"2026-07-25",'
        '"monsoonStart":"2026-06-01","monsoonEnd":"2026-09-30",'
        '"severity":"OVERLAP_FULL"}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final warnings = await service.warningsFor(42);
    expect(warnings, hasLength(1));
    expect(warnings.first.taskId, 7);
    expect(warnings.first.taskName, contains('Slab'));
  });

  test('warningsFor returns empty list when project has no warnings',
      () async {
    adapter.mock('GET', '/api/projects/99/schedule/warnings', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final warnings = await service.warningsFor(99);
    expect(warnings, isEmpty);
  });
}
