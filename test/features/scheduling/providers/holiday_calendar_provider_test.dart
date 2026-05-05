import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/holiday_admin_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';
import 'package:admin/features/scheduling/providers/holiday_calendar_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late HolidayCalendarProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = HolidayCalendarProvider(service: HolidayAdminService(dio: dio));
  });

  test('load fetches with current filters', () async {
    adapter.mock('GET', '/api/admin/holidays', (options) {
      expect(options.queryParameters['year'], 2026);
      expect(options.queryParameters['scope'], 'STATE');
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"name":"Onam","date":"2026-08-26",'
        '"scope":"STATE","scopeRef":"KL","recurrenceType":"LUNAR","isActive":true}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    provider.setYear(2026);
    provider.setScope(HolidayScope.state, scopeRef: 'KL');
    await provider.load();
    expect(provider.holidays, hasLength(1));
    expect(provider.holidays.first.name, 'Onam');
  });

  test('create POSTs and reloads', () async {
    var listCount = 0;
    adapter.mock('GET', '/api/admin/holidays', (_) {
      listCount++;
      return ResponseBody.fromString(
        '{"success":true,"data":[]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('POST', '/api/admin/holidays', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":2,"name":"X","date":"2026-01-01",'
        '"scope":"NATIONAL","recurrenceType":"FIXED_DATE","isActive":true}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });
    final ok = await provider.create(Holiday(
      name: 'X',
      date: DateTime.utc(2026, 1, 1),
      scope: HolidayScope.national,
      recurrenceType: HolidayRecurrenceType.fixedDate,
      isActive: true,
    ));
    expect(ok, isTrue);
    expect(listCount, 1);
  });

  test('importYaml triggers list reload and reports count', () async {
    var listCount = 0;
    adapter.mock('GET', '/api/admin/holidays', (_) {
      listCount++;
      return ResponseBody.fromString(
        '{"success":true,"data":[]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    adapter.mock('POST', '/api/admin/holidays/import-yaml', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"imported":12}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final n = await provider.importYaml(year: 2026);
    expect(n, 12);
    expect(listCount, 1);
  });
}
