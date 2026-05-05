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

  test('list filters by year + scope and returns Holiday models', () async {
    adapter.mock('GET', '/api/admin/holidays', (options) {
      expect(options.queryParameters['year'], 2026);
      expect(options.queryParameters['scope'], 'STATE');
      expect(options.queryParameters['scopeRef'], 'KL');
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"code":"KL_ONAM_DAY1","name":"Onam Day 1",'
        '"date":"2026-08-26","scope":"STATE","scopeRef":"KL",'
        '"recurrenceType":"LUNAR","isActive":true}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final out =
        await service.list(year: 2026, scope: HolidayScope.state, scopeRef: 'KL');
    expect(out, hasLength(1));
    expect(out.first.name, 'Onam Day 1');
    expect(out.first.scope, HolidayScope.state);
  });

  test('create POSTs the right body', () async {
    adapter.mock('POST', '/api/admin/holidays', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['name'], 'Test Day');
      expect(body['date'], '2026-12-31');
      expect(body['scope'], 'PROJECT');
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":99,"name":"Test Day","date":"2026-12-31",'
        '"scope":"PROJECT","scopeRef":"42","recurrenceType":"ONE_OFF","isActive":true}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    final created = await service.create(Holiday(
      name: 'Test Day',
      date: DateTime.utc(2026, 12, 31),
      scope: HolidayScope.project,
      scopeRef: '42',
      recurrenceType: HolidayRecurrenceType.oneOff,
      isActive: true,
    ));
    expect(created.id, 99);
  });

  test('update PATCHes only changed fields', () async {
    adapter.mock('PATCH', '/api/admin/holidays/5', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['isActive'], false);
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":5,"name":"X","date":"2026-01-01",'
        '"scope":"NATIONAL","recurrenceType":"FIXED_DATE","isActive":false}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final updated = await service.patch(5, {'isActive': false});
    expect(updated.isActive, isFalse);
  });

  test('delete sends DELETE request', () async {
    var called = false;
    adapter.mock('DELETE', '/api/admin/holidays/5', (_) {
      called = true;
      return ResponseBody.fromString(
        '{"success":true}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    await service.delete(5);
    expect(called, isTrue);
  });

  test('importYaml POSTs to bulk endpoint', () async {
    adapter.mock('POST', '/api/admin/holidays/import-yaml', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['year'], 2026);
      return ResponseBody.fromString(
        '{"success":true,"data":{"imported":12}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    final n = await service.importYaml(year: 2026);
    expect(n, 12);
  });
}
