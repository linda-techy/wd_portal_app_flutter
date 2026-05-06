import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/cpm_service.dart';
import 'package:admin/features/projects/providers/gantt_cpm_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late CpmService service;
  late GanttCpmProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = CpmService(dio: dio);
    provider = GanttCpmProvider(service: service);
  });

  String okBody() => '{'
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
      '}';

  test('load populates cpmByTaskId and notifies listeners', () async {
    adapter.mock('GET', '/api/projects/42/cpm', (_) {
      return ResponseBody.fromString(
        okBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    var notifyCount = 0;
    provider.addListener(() => notifyCount++);

    await provider.load(42);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.cpmByTaskId.length, 2);
    expect(provider.cpmByTaskId[101]!.isCritical, isTrue);
    expect(provider.cpmByTaskId[102]!.totalFloatDays, 3);
    expect(provider.projectFinishDate, DateTime.utc(2026, 9, 30));
    expect(provider.criticalPathTaskIds, [101]);
    // At least loading-true → loading-false.
    expect(notifyCount, greaterThanOrEqualTo(2));
  });

  test('load 404 sets errorMessage and clears the map', () async {
    adapter.mock('GET', '/api/projects/999/cpm', (_) {
      return ResponseBody.fromString(
        '{"message":"Project not found"}',
        404,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    await provider.load(999);

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNotNull);
    expect(provider.errorMessage!.isNotEmpty, isTrue);
    expect(provider.cpmByTaskId, isEmpty);
  });

  test('clear empties state and notifies listeners', () async {
    adapter.mock('GET', '/api/projects/42/cpm', (_) {
      return ResponseBody.fromString(
        okBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.load(42);
    expect(provider.cpmByTaskId, isNotEmpty);

    var notifyCount = 0;
    provider.addListener(() => notifyCount++);
    provider.clear();

    expect(provider.cpmByTaskId, isEmpty);
    expect(provider.projectFinishDate, isNull);
    expect(provider.criticalPathTaskIds, isEmpty);
    expect(notifyCount, greaterThanOrEqualTo(1));
  });
}
