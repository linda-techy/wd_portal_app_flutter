import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/holiday_admin_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late HolidayAdminService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = HolidayAdminService(dio: dio);
  });

  test('list sends required scope + year and parses raw body', () async {
    adapter.mock('GET', '/api/admin/holidays', (options) {
      // Real backend requires both as @RequestParam — null = 400.
      expect(options.queryParameters['scope'], 'STATE');
      expect(options.queryParameters['year'], 2026);
      return ResponseBody.fromString(
        '[{"id":1,"code":"KL_ONAM_DAY1","name":"Onam Day 1",'
        '"date":"2026-08-26","scope":"STATE","scopeRef":"KL",'
        '"recurrenceType":"LUNAR","active":true}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final out = await service.list(scope: HolidayScope.state, year: 2026);
    expect(out, hasLength(1));
    expect(out.first.name, 'Onam Day 1');
    expect(out.first.scope, HolidayScope.state);
    expect(out.first.active, isTrue);
  });

  test('create POSTs the right body', () async {
    adapter.mock('POST', '/api/admin/holidays', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['name'], 'Test Day');
      expect(body['date'], '2026-12-31');
      expect(body['scope'], 'PROJECT');
      // Field name aligns with Jackson serialization of `Boolean active`.
      expect(body['active'], isTrue);
      return ResponseBody.fromString(
        '{"id":99,"name":"Test Day","date":"2026-12-31",'
        '"scope":"PROJECT","scopeRef":"42","recurrenceType":"ONE_OFF","active":true}',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final created = await service.create(Holiday(
      name: 'Test Day',
      date: DateTime.utc(2026, 12, 31),
      scope: HolidayScope.project,
      scopeRef: '42',
      recurrenceType: HolidayRecurrenceType.oneOff,
      active: true,
    ));
    expect(created.id, 99);
  });

  test('update PATCHes only changed fields', () async {
    adapter.mock('PATCH', '/api/admin/holidays/5', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['active'], false);
      return ResponseBody.fromString(
        '{"id":5,"name":"X","date":"2026-01-01",'
        '"scope":"NATIONAL","recurrenceType":"FIXED_DATE","active":false}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final updated = await service.patch(5, {'active': false});
    expect(updated.active, isFalse);
  });

  test('delete sends DELETE request', () async {
    var called = false;
    adapter.mock('DELETE', '/api/admin/holidays/5', (_) {
      called = true;
      return ResponseBody.fromString(
        '',
        204,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await service.delete(5);
    expect(called, isTrue);
  });
}
