import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/presentation/screens/wbs_template_editor_screen.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('renders phase list and task table for the selected phase',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/wbs/templates/3', (_) {
      return ResponseBody.fromString(
        '{"id":3,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":2,"isActive":true,"phases":['
        '{"id":10,"sequence":1,"name":"Foundation","monsoonSensitive":false,'
        '"tasks":[{"id":100,"sequence":1,"name":"Excavation","durationDays":5,'
        '"monsoonSensitive":false,"isPaymentMilestone":false,"floorLoop":"NONE",'
        '"predecessors":[]}]},'
        '{"id":11,"sequence":2,"name":"Superstructure","monsoonSensitive":true,'
        '"tasks":[]}'
        ']}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final provider = WbsTemplateProvider(service: WbsTemplateService(dio: dio));
    await tester.runAsync(() => provider.loadEditing(3));

    final perms = PermissionProvider();
    perms.setPermissions(
        ['WBS_TEMPLATE_VIEW', 'WBS_TEMPLATE_MANAGE'], 'SCHEDULER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: WbsTemplateEditorScreen(
          templateId: 3,
          providerOverride: provider,
        ),
      ),
    ));
    await tester.pump();

    // "Foundation" appears in both phase list (left pane) and as the
    // selected-phase header (right pane), so allow >= 1.
    expect(find.text('Foundation'), findsAtLeastNWidgets(1));
    expect(find.text('Superstructure'), findsOneWidget);
    expect(find.text('Excavation'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
  });
}
