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
        '{"success":true,"data":{"projectId":42,"sundayWorking":false,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}}',
        200,
        headers: {'content-type': ['application/json']},
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
        '{"success":true,"data":{"projectId":42,"sundayWorking":true,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}}',
        200,
        headers: {'content-type': ['application/json']},
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

  test('addOverride POSTs override and returns the row', () async {
    adapter.mock('POST', '/api/projects/42/holiday-overrides', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['holidayId'], 7);
      expect(body['action'], 'EXCLUDE');
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":1,"projectId":42,"holidayId":7,"action":"EXCLUDE"}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });
    final ov = await service.addOverride(
      projectId: 42,
      holidayId: 7,
      action: HolidayOverrideAction.exclude,
    );
    expect(ov.id, 1);
  });

  test('deleteOverride sends DELETE', () async {
    var called = false;
    adapter.mock('DELETE', '/api/projects/42/holiday-overrides/1', (_) {
      called = true;
      return ResponseBody.fromString(
        '{"success":true}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    await service.deleteOverride(projectId: 42, overrideId: 1);
    expect(called, isTrue);
  });

  test('listOverrides returns list', () async {
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"projectId":42,"holidayId":7,"action":"EXCLUDE"}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final out = await service.listOverrides(42);
    expect(out, hasLength(1));
    expect(out.first.action, HolidayOverrideAction.exclude);
  });
}
