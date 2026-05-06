import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/services/cpm_service.dart';
import 'package:admin/features/projects/providers/gantt_cpm_provider.dart';
import 'package:admin/features/projects/presentation/screens/gantt_screen.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

/// Mock body returned by `GET /api/projects/{id}/schedule/gantt` — two tasks
/// with ids matching the CPM fixture (101 critical, 102 non-critical+float).
String _ganttBody() => '{'
    '"projectId":1,'
    '"projectStartDate":"2026-06-01",'
    '"projectEndDate":"2026-06-10",'
    '"overallProgress":0,'
    '"overdueTasks":0,'
    '"tasks":['
    '{"id":101,"title":"Site Prep","status":"PENDING",'
    '"startDate":"2026-06-01","endDate":"2026-06-05",'
    '"progressPercent":0,"overdue":false},'
    '{"id":102,"title":"Permit","status":"PENDING",'
    '"startDate":"2026-06-01","endDate":"2026-06-03",'
    '"progressPercent":0,"overdue":false}'
    ']'
    '}';

/// Mock body for `GET /api/projects/{id}/cpm`.
String _cpmBody() => '{'
    '"projectId":1,'
    '"projectStartDate":"2026-06-01",'
    '"projectFinishDate":"2026-06-05",'
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

void main() {
  // Save and restore the singleton's adapter + interceptors. The shared
  // ApiService singleton ships an AuthInterceptor that calls platform-channel
  // storage, which hangs in widget tests; clearing interceptors for the
  // duration of the test lets requests reach the mock adapter directly.
  late HttpClientAdapter savedAdapter;
  late List<Interceptor> savedInterceptors;
  late MockDioAdapter adapter;

  setUp(() {
    savedAdapter = ApiService().dio.httpClientAdapter;
    savedInterceptors = List.of(ApiService().dio.interceptors);
    adapter = MockDioAdapter();
    ApiService().dio.httpClientAdapter = adapter;
    ApiService().dio.interceptors.clear();
  });

  tearDown(() {
    ApiService().dio.httpClientAdapter = savedAdapter;
    ApiService().dio.interceptors
      ..clear()
      ..addAll(savedInterceptors);
  });

  testWidgets('GanttScreen loads both schedule and CPM endpoints', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var ganttHits = 0;
    var cpmHits = 0;
    adapter.mock('GET', '/api/projects/1/schedule/gantt', (options) {
      ganttHits++;
      return ResponseBody.fromString(
        _ganttBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('GET', '/api/projects/1/schedule/warnings', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    // Provider-level CPM mock: own Dio so we don't conflict with the
    // singleton's mocks.
    final cpmDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final cpmAdapter = MockDioAdapter();
    cpmDio.httpClientAdapter = cpmAdapter;
    cpmAdapter.mock('GET', '/api/projects/1/cpm', (_) {
      cpmHits++;
      return ResponseBody.fromString(
        _cpmBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final cpmProvider = GanttCpmProvider(service: CpmService(dio: cpmDio));

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<GanttCpmProvider>.value(
        value: cpmProvider,
        child: const GanttScreen(projectId: 1, projectName: 'Test Project'),
      ),
    ));
    // First frame triggers _load(); post-frame callback triggers cpm load.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(ganttHits, greaterThanOrEqualTo(1));
    expect(cpmHits, greaterThanOrEqualTo(1));
    // App bar still shows the project name — render didn't crash.
    expect(find.textContaining('Test Project'), findsOneWidget);
  });

  testWidgets('renders critical-path bar (red+flame) and amber float bar',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    adapter.mock('GET', '/api/projects/1/schedule/gantt', (_) {
      return ResponseBody.fromString(
        _ganttBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    adapter.mock('GET', '/api/projects/1/schedule/warnings', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final cpmDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final cpmAdapter = MockDioAdapter();
    cpmDio.httpClientAdapter = cpmAdapter;
    cpmAdapter.mock('GET', '/api/projects/1/cpm', (_) {
      return ResponseBody.fromString(
        _cpmBody(),
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final cpmProvider = GanttCpmProvider(service: CpmService(dio: cpmDio));

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<GanttCpmProvider>.value(
        value: cpmProvider,
        child: const GanttScreen(projectId: 1, projectName: 'Test Project'),
      ),
    ));
    // Settle both fetches and the post-frame callback.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Flame icon shows on row label for the critical task (101) — there
    // are two PENDING task labels; only the critical one gets the flame.
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

    // Critical task bar — fill is red.shade400.
    final criticalBar = tester.widget<Container>(
      find.byKey(const Key('gantt-bar-101')),
    );
    final criticalDeco = criticalBar.decoration as BoxDecoration;
    expect(criticalDeco.color, Colors.red.shade400);
    expect(criticalDeco.border, isNotNull);
    expect(
      (criticalDeco.border as Border).top.color,
      Colors.red.shade700,
    );

    // Non-critical task bar — fill stays the existing default for PENDING
    // (`Colors.blueGrey.shade300`), no red border.
    final normalBar = tester.widget<Container>(
      find.byKey(const Key('gantt-bar-102')),
    );
    final normalDeco = normalBar.decoration as BoxDecoration;
    expect(normalDeco.color, Colors.blueGrey.shade300);

    // Float bar present for task 102 (totalFloatDays=3), color amber.shade300,
    // height 4px.
    expect(find.byKey(const Key('gantt-float-102')), findsOneWidget);
    final floatBar = tester.widget<Container>(
      find.byKey(const Key('gantt-float-102')),
    );
    expect(floatBar.color, Colors.amber.shade300);
    final floatSize = floatBar.constraints;
    expect(floatSize?.maxHeight, 4);

    // No float bar for task 101 (critical, float=0).
    expect(find.byKey(const Key('gantt-float-101')), findsNothing);

    // Tooltip on task 102 mentions float days.
    final tooltip = tester.widget<Tooltip>(
      find.byKey(const Key('gantt-bar-tooltip-102')),
    );
    expect(tooltip.message, contains('Float: 3 days'));
    expect(tooltip.message, contains('ES'));
    expect(tooltip.message, contains('EF'));
    expect(tooltip.message, contains('LS'));
    expect(tooltip.message, contains('LF'));
  });
}
