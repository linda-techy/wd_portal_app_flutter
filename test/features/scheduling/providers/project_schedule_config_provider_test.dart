import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/project_schedule_config_service.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';
import 'package:admin/features/scheduling/providers/project_schedule_config_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late ProjectScheduleConfigProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = ProjectScheduleConfigProvider(
      projectId: 42,
      service: ProjectScheduleConfigService(dio: dio),
    );
  });

  test('load fetches config and overrides in parallel', () async {
    adapter.mock('GET', '/api/projects/42/schedule-config', (_) {
      return ResponseBody.fromString(
        '{"projectId":42,"sundayWorking":false,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"projectId":42,"holidayId":7,"overrideDate":"2026-08-15",'
        '"action":"EXCLUDE"}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.load();
    expect(provider.config, isNotNull);
    expect(provider.config!.districtCode, 'KL-EKM');
    expect(provider.overrides, hasLength(1));
  });

  test('save PUTs config and refreshes', () async {
    adapter.mock('GET', '/api/projects/42/schedule-config', (_) {
      return ResponseBody.fromString(
        '{"projectId":42,"sundayWorking":false,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('PUT', '/api/projects/42/schedule-config', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['sundayWorking'], true);
      return ResponseBody.fromString(
        '{"projectId":42,"sundayWorking":true,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.load();
    final ok =
        await provider.save(provider.config!.copyWith(sundayWorking: true));
    expect(ok, isTrue);
    expect(provider.config!.sundayWorking, isTrue);
  });

  test('addOverride POSTs new shape and refreshes from list endpoint',
      () async {
    var listCount = 0;
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      listCount++;
      return ResponseBody.fromString(
        '[{"id":99,"projectId":42,"holidayId":7,"overrideDate":"2026-08-15",'
        '"action":"EXCLUDE"}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('POST', '/api/projects/42/holiday-overrides', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['action'], 'EXCLUDE');
      expect(body['overrideDate'], '2026-08-15');
      expect(body['holidayId'], 7);
      return ResponseBody.fromString(
        '99',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final ok = await provider.addOverride(
      action: HolidayOverrideAction.exclude,
      overrideDate: DateTime.utc(2026, 8, 15),
      holidayId: 7,
    );
    expect(ok, isTrue);
    expect(listCount, 1);
    expect(provider.overrides, hasLength(1));
    expect(provider.overrides.first.id, 99);
  });
}
