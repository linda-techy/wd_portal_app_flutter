import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/presentation/screens/wbs_template_list_screen.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('renders template cards from provider', (tester) async {
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

    final perms = PermissionProvider();
    perms.setPermissions(
        ['WBS_TEMPLATE_VIEW', 'WBS_TEMPLATE_MANAGE'], 'SCHEDULER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: WbsTemplateListScreen(providerOverride: provider),
      ),
    ));
    await tester.pump();

    expect(find.text('WBS Templates'), findsOneWidget);
    expect(find.textContaining('Residential'), findsAtLeastNWidgets(1));
    expect(find.text('v1'), findsOneWidget);
  });

  testWidgets('hides edit button when WBS_TEMPLATE_MANAGE missing',
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

    final perms = PermissionProvider();
    perms.setPermissions(['WBS_TEMPLATE_VIEW'], 'SITE_ENGINEER');

    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PermissionProvider>.value(
        value: perms,
        child: WbsTemplateListScreen(providerOverride: provider),
      ),
    ));
    await tester.pump();

    expect(find.byIcon(Icons.edit), findsNothing);
    // "New version" button is also gated on MANAGE permission
    expect(find.text('New version'), findsNothing);
  });
}
