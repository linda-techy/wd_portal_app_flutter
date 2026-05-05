import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/presentation/screens/wbs_template_editor_screen.dart';
import 'package:admin/features/scheduling/presentation/screens/wbs_template_list_screen.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('SITE_ENGINEER sees no edit/save affordances on list screen',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/admin/wbs-templates', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final provider = WbsTemplateProvider(service: WbsTemplateService(dio: dio));
    await tester.runAsync(() => provider.loadList());

    // Site engineer has NO WBS_TEMPLATE_MANAGE permission.
    // Per the matrix in the spec they DO have WBS_TEMPLATE_VIEW.
    final perms = PermissionProvider();
    perms.setPermissions(['WBS_TEMPLATE_VIEW'], 'SITE_ENGINEER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: WbsTemplateListScreen(providerOverride: provider),
      ),
    ));
    await tester.pump();

    // Edit + New version controls should be missing.
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.text('New version'), findsNothing);
  });

  testWidgets('SITE_ENGINEER editor screen has no Save button', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/admin/wbs-templates/1', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final provider = WbsTemplateProvider(service: WbsTemplateService(dio: dio));
    await tester.runAsync(() => provider.loadEditing(1));

    final perms = PermissionProvider();
    perms.setPermissions(['WBS_TEMPLATE_VIEW'], 'SITE_ENGINEER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: WbsTemplateEditorScreen(
          templateId: 1,
          providerOverride: provider,
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Save as new version'), findsNothing);
    expect(find.text('Add task'), findsNothing);
  });
}
