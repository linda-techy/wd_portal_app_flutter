import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/services/project_schedule_config_service.dart';
import 'package:admin/features/scheduling/presentation/widgets/project_schedule_config_tab.dart';
import 'package:admin/features/scheduling/providers/project_schedule_config_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('renders sunday-working toggle and district from API',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/projects/42/schedule-config', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"projectId":42,"sundayWorking":true,'
        '"monsoonStartMonthDay":601,"monsoonEndMonthDay":930,"districtCode":"KL-EKM"}}',
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

    final provider = ProjectScheduleConfigProvider(
      projectId: 42,
      service: ProjectScheduleConfigService(dio: dio),
    );
    await tester.runAsync(() => provider.load());

    final perms = PermissionProvider();
    perms.setPermissions(
        ['PROJECT_SCHEDULE_CONFIG_EDIT', 'PROJECT_HOLIDAY_OVERRIDE'],
        'PROJECT_MANAGER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: Scaffold(
          body: ProjectScheduleConfigTab(
            projectId: 42,
            providerOverride: provider,
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Schedule configuration'), findsOneWidget);
    expect(find.text('Sunday is a working day'), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Sunday is a working day'),
    );
    expect(sw.value, isTrue);
    expect(find.textContaining('KL-EKM'), findsAtLeastNWidgets(1));
  });
}
