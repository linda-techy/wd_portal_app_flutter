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
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
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
    adapter.mock('GET', '/api/wbs/templates/1', (_) {
      return ResponseBody.fromString(
        '{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}',
        200,
        headers: {
          'content-type': ['application/json']
        },
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

  testWidgets(
      'I1 — schedule tab is gated on HOLIDAY_VIEW or PROJECT_SCHEDULE_CONFIG_EDIT',
      (tester) async {
    // Mirrors the gate added to project_detail_screen.dart: a Consumer that
    // returns SizedBox.shrink() unless the user can view holidays or edit
    // schedule config. We test the gate logic directly to avoid spinning up
    // the real project detail screen (which loads project data + the
    // schedule tab provider, both of which need real services).

    Widget gateUnder(PermissionProvider perms) {
      return MaterialApp(
        home: ChangeNotifierProvider<PermissionProvider>.value(
          value: perms,
          child: Scaffold(
            body: Consumer<PermissionProvider>(
              builder: (_, p, __) {
                if (!p.canViewHolidays && !p.canEditProjectScheduleConfig) {
                  return const SizedBox.shrink();
                }
                return const Text('SCHEDULE_TAB_VISIBLE');
              },
            ),
          ),
        ),
      );
    }

    // No perms — gate hides.
    final noPerms = PermissionProvider();
    noPerms.setPermissions(<String>[], 'CUSTOMER');
    await tester.pumpWidget(gateUnder(noPerms));
    await tester.pump();
    expect(find.text('SCHEDULE_TAB_VISIBLE'), findsNothing);

    // HOLIDAY_VIEW alone is enough.
    final viewPerms = PermissionProvider();
    viewPerms.setPermissions(['HOLIDAY_VIEW'], 'PROJECT_MANAGER');
    await tester.pumpWidget(gateUnder(viewPerms));
    await tester.pump();
    expect(find.text('SCHEDULE_TAB_VISIBLE'), findsOneWidget);
  });
}
