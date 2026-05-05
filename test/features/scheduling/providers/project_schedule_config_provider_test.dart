import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/project_schedule_config_service.dart';
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
        '{"success":true,"data":{"projectId":42,"sundayWorking":false,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"projectId":42,"holidayId":7,"action":"EXCLUDE"}]}',
        200,
        headers: {'content-type': ['application/json']},
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
        '{"success":true,"data":{"projectId":42,"sundayWorking":false,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('GET', '/api/projects/42/holiday-overrides', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('PUT', '/api/projects/42/schedule-config', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['sundayWorking'], true);
      return ResponseBody.fromString(
        '{"success":true,"data":{"projectId":42,"sundayWorking":true,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    await provider.load();
    final ok = await provider.save(provider.config!.copyWith(sundayWorking: true));
    expect(ok, isTrue);
    expect(provider.config!.sundayWorking, isTrue);
  });
}
