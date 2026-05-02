import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/services/market_index_admin_service.dart';
import 'package:admin/features/estimation_settings/presentation/screens/market_index_screen.dart';
import 'package:admin/features/estimation_settings/providers/market_index_provider.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets(
      'MarketIndexScreen renders 2 snapshots with ACTIVE chip and composite index',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/estimation/market-index', (_) {
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"s1","snapshotDate":"2026-05-02","steelRate":65.0,"cementRate":415.0,
            "sandRate":5800.0,"aggregateRate":1850.0,"tilesRate":38.0,"electricalRate":92.0,
            "paintsRate":285.0,"weights":{"steel":"0.30","cement":"0.20","sand":"0.12",
            "aggregate":"0.08","tiles":"0.12","electrical":"0.10","paints":"0.08"},
            "compositeIndex":1.0156,"active":true},
          {"id":"s0","snapshotDate":"2026-04-30","steelRate":62.5,"cementRate":410.0,
            "sandRate":5800.0,"aggregateRate":1850.0,"tilesRate":38.0,"electricalRate":92.0,
            "paintsRate":285.0,"weights":{"steel":"0.30","cement":"0.20","sand":"0.12",
            "aggregate":"0.08","tiles":"0.12","electrical":"0.10","paints":"0.08"},
            "compositeIndex":1.0000,"active":false}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final provider = MarketIndexProvider(
      service: MarketIndexAdminService(dio: dio),
    );
    // runAsync escapes fakeAsync so real Dio futures resolve correctly.
    await tester.runAsync(() => provider.load());

    // MarketIndexScreen's AppBar reads PermissionProvider — supply a default one.
    final permissionProvider = PermissionProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<PermissionProvider>.value(
        value: permissionProvider,
        child: MaterialApp(
          home: MarketIndexScreen(providerOverride: provider),
        ),
      ),
    );
    // Use pump() rather than pumpAndSettle() — pumpAndSettle loops forever on
    // screens that contain Tooltip widgets (they schedule recurring frames).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Market Index'), findsOneWidget); // AppBar title
    expect(find.text('2026-05-02'), findsOneWidget);
    expect(find.text('2026-04-30'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });
}
