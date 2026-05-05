import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/project_schedule_config_service.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late ProjectScheduleConfigService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = ProjectScheduleConfigService(dio: dio);
  });

  test('get parses MMDD smallint into month/day pairs', () async {
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

    final cfg = await service.get(42);
    expect(cfg.monsoonStartMonth, 6);
    expect(cfg.monsoonStartDay, 1);
    expect(cfg.monsoonEndMonth, 9);
    expect(cfg.monsoonEndDay, 30);
    expect(cfg.districtCode, 'KL-EKM');
  });

  test('put sends MMDD smallints back to server', () async {
    adapter.mock('PUT', '/api/projects/42/schedule-config', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['monsoonStartMonthDay'], 601);
      expect(body['monsoonEndMonthDay'], 930);
      expect(body['sundayWorking'], true);
      return ResponseBody.fromString(
        '{"projectId":42,"sundayWorking":true,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    const cfg = ProjectScheduleConfig(
      projectId: 42,
      sundayWorking: true,
      monsoonStartMonth: 6,
      monsoonStartDay: 1,
      monsoonEndMonth: 9,
      monsoonEndDay: 30,
      districtCode: 'KL-EKM',
    );
    final saved = await service.put(cfg);
    expect(saved.sundayWorking, isTrue);
  });

  test('addOverride POSTs action+date+holidayId+name and returns Long id',
      () async {
    adapter.mock('POST', '/api/projects/42/holiday-overrides', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['action'], 'EXCLUDE');
      expect(body['overrideDate'], '2026-08-15');
      expect(body['holidayId'], 7);
      // Backend returns a raw Long, not a DTO.
      return ResponseBody.fromString(
        '99',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final newId = await service.addOverride(
      projectId: 42,
      action: HolidayOverrideAction.exclude,
      overrideDate: DateTime.utc(2026, 8, 15),
      holidayId: 7,
    );
    expect(newId, 99);
  });

  test('addOverride for project-only ADD omits holidayId, includes name',
      () async {
    adapter.mock('POST', '/api/projects/42/holiday-overrides', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['action'], 'ADD');
      expect(body['overrideDate'], '2026-12-25');
      expect(body.containsKey('holidayId'), isFalse);
      expect(body['overrideName'], 'Site closure');
      return ResponseBody.fromString(
        '101',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final newId = await service.addOverride(
      projectId: 42,
      action: HolidayOverrideAction.add,
      overrideDate: DateTime.utc(2026, 12, 25),
      overrideName: 'Site closure',
    );
    expect(newId, 101);
  });

  test('deleteOverride sends DELETE', () async {
    var called = false;
    adapter.mock('DELETE', '/api/projects/42/holiday-overrides/1', (_) {
      called = true;
      return ResponseBody.fromString(
        '',
        204,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await service.deleteOverride(projectId: 42, overrideId: 1);
    expect(called, isTrue);
  });

  test('listOverrides returns list with overrideDate + nullable holidayId',
      () async {
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"projectId":42,"holidayId":7,"overrideDate":"2026-08-15",'
        '"action":"EXCLUDE"},'
        '{"id":2,"projectId":42,"holidayId":null,"overrideDate":"2026-12-25",'
        '"overrideName":"Site closure","action":"ADD"}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final out = await service.listOverrides(42);
    expect(out, hasLength(2));
    expect(out.first.action, HolidayOverrideAction.exclude);
    expect(out.first.holidayId, 7);
    expect(out[1].holidayId, isNull);
    expect(out[1].overrideName, 'Site closure');
  });
}
