import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/services/package_rate_version_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/rate_versions_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('list renders 2 rate versions with ACTIVE badge on the open-ended row', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"v1","packageId":"p1","projectType":"NEW_BUILD","materialRate":1500,"labourRate":550,"overheadRate":300,"effectiveFrom":"2026-04-01","effectiveTo":null},
          {"id":"v0","packageId":"p1","projectType":"NEW_BUILD","materialRate":1420,"labourRate":520,"overheadRate":280,"effectiveFrom":"2026-01-01","effectiveTo":"2026-03-31"}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    // Mirror the B.PR-2 packages_list_screen_test pattern: trigger the load
    // inside the provider's create callback, then pumpAndSettle waits for it.
    // (Awaiting the load before pumpWidget hangs flutter_test's fake-async
    // scheduler — see B.PR-2 packages_list_screen_test for the same shape.)
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<RateVersionsProvider>(
        create: (_) {
          final p = RateVersionsProvider(
            service: PackageRateVersionAdminService(dio: dio),
          );
          p.select(packageId: 'p1');
          return p;
        },
        child: Scaffold(
          body: Consumer<RateVersionsProvider>(
            builder: (context, p, _) {
              if (p.isLoading) return const Center(child: CircularProgressIndicator());
              return ListView(
                children: p.versions.map((v) => ListTile(
                  title: Text('${v.effectiveFrom.toIso8601String().substring(0, 10)} → ${v.effectiveTo == null ? 'present' : v.effectiveTo!.toIso8601String().substring(0, 10)}'),
                  trailing: v.isActive ? const Chip(label: Text('ACTIVE')) : null,
                )).toList(),
              );
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2026-04-01 → present'), findsOneWidget);
    expect(find.text('2026-01-01 → 2026-03-31'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });
}
