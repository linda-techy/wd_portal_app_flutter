import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/services/holiday_admin_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';
import 'package:admin/features/scheduling/presentation/screens/holiday_calendar_screen.dart';
import 'package:admin/features/scheduling/providers/holiday_calendar_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('lists holidays returned by the API', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/admin/holidays', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"name":"Onam Day 1","date":"2026-08-26",'
        '"scope":"STATE","scopeRef":"KL","recurrenceType":"LUNAR","active":true},'
        '{"id":2,"name":"Independence Day","date":"2026-08-15",'
        '"scope":"NATIONAL","recurrenceType":"FIXED_DATE","active":true}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final provider =
        HolidayCalendarProvider(service: HolidayAdminService(dio: dio));
    provider.setYear(2026);
    provider.setScope(HolidayScope.state);
    await tester.runAsync(() => provider.load());

    final perms = PermissionProvider();
    perms.setPermissions(['HOLIDAY_VIEW', 'HOLIDAY_MANAGE'], 'ADMIN');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: HolidayCalendarScreen(providerOverride: provider),
      ),
    ));
    await tester.pump();

    expect(find.text('Holiday Calendar'), findsOneWidget);
    expect(find.text('Onam Day 1'), findsOneWidget);
    expect(find.text('Independence Day'), findsOneWidget);
    // Import YAML button should not exist (B7 — endpoint doesn't exist).
    expect(find.text('Import YAML'), findsNothing);
  });

  testWidgets('hides Add (FAB) when HOLIDAY_MANAGE missing', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/admin/holidays', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final provider =
        HolidayCalendarProvider(service: HolidayAdminService(dio: dio));
    await tester.runAsync(() => provider.load());

    final perms = PermissionProvider();
    perms.setPermissions(['HOLIDAY_VIEW'], 'PROJECT_MANAGER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: HolidayCalendarScreen(providerOverride: provider),
      ),
    ));
    await tester.pump();

    expect(find.text('Import YAML'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
