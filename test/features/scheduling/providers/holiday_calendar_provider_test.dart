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

  test('load fetches with current year + scope', () async {
    adapter.mock('GET', '/api/admin/holidays', (options) {
      expect(options.queryParameters['year'], 2026);
      expect(options.queryParameters['scope'], 'STATE');
      return ResponseBody.fromString(
        '[{"id":1,"name":"Onam","date":"2026-08-26",'
        '"scope":"STATE","scopeRef":"KL","recurrenceType":"LUNAR","active":true}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    provider.setYear(2026);
    provider.setScope(HolidayScope.state, scopeRef: 'KL');
    await provider.load();
    expect(provider.holidays, hasLength(1));
    expect(provider.holidays.first.name, 'Onam');
  });

  test('client-side scopeRef filter narrows the cached list', () async {
    adapter.mock('GET', '/api/admin/holidays', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"name":"Onam","date":"2026-08-26","scope":"STATE",'
        '"scopeRef":"KL","recurrenceType":"LUNAR","active":true},'
        '{"id":2,"name":"Pongal","date":"2026-01-14","scope":"STATE",'
        '"scopeRef":"TN","recurrenceType":"FIXED_DATE","active":true}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
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
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('POST', '/api/admin/holidays', (_) {
      return ResponseBody.fromString(
        '{"id":2,"name":"X","date":"2026-01-01",'
        '"scope":"NATIONAL","recurrenceType":"FIXED_DATE","active":true}',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final ok = await provider.create(Holiday(
      name: 'X',
      date: DateTime.utc(2026, 1, 1),
      scope: HolidayScope.national,
      recurrenceType: HolidayRecurrenceType.fixedDate,
      active: true,
    ));
    expect(ok, isTrue);
    expect(listCount, 1);
  });
}
