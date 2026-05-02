import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/services/market_index_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/market_index_provider.dart';

import '../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('list renders 2 snapshots with ACTIVE chip on the open row + composite index', (tester) async {
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

    // Same gotcha as B'.Task 6 / B.PR-2: trigger load inside the provider's
    // create callback instead of awaiting before pumpWidget.
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<MarketIndexProvider>(
        create: (_) {
          final p = MarketIndexProvider(
            service: MarketIndexAdminService(dio: dio),
          );
          p.load();
          return p;
        },
        child: Scaffold(
          body: Consumer<MarketIndexProvider>(
            builder: (context, p, _) {
              if (p.isLoading) return const Center(child: CircularProgressIndicator());
              return ListView(
                children: p.snapshots.map((s) => ListTile(
                  title: Text(s.snapshotDate.toIso8601String().substring(0, 10)),
                  subtitle: Text('composite ${s.compositeIndex.toStringAsFixed(4)}'),
                  trailing: s.active ? const Chip(label: Text('ACTIVE')) : null,
                )).toList(),
              );
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2026-05-02'), findsOneWidget);
    expect(find.text('2026-04-30'), findsOneWidget);
    expect(find.text('composite 1.0156'), findsOneWidget);
    expect(find.text('composite 1.0000'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });
}
