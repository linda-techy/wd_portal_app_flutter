import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _threePackagesJson = '''{
  "success": true,
  "data": [
    {"id":"u1","internalName":"BASIC","marketingName":"Foundation Series","displayOrder":10,"active":true},
    {"id":"u2","internalName":"STANDARD","marketingName":"Signature","displayOrder":20,"active":true},
    {"id":"u3","internalName":"PREMIUM","marketingName":"Luxe","displayOrder":30,"active":true}
  ]
}''';

void main() {
  testWidgets('list renders the 3 packages from the API', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        _threePackagesJson, 200,
        headers: {'content-type': ['application/json']},
      );
    });

    // The `..load()` cascade inside the create callback (rather than
    // awaiting before pumpWidget) is intentional: awaiting an async load
    // outside the test pump cycle deadlocks Flutter test's fake-async
    // scheduler. See B'.Task 6 rate_card_screen_test for the same pattern.
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<EstimationPackagesProvider>(
        create: (_) => EstimationPackagesProvider(
          service: EstimationPackageAdminService(dio: dio),
        )..load(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Estimation Packages')),
          body: Consumer<EstimationPackagesProvider>(
            builder: (context, p, _) {
              if (p.isLoading) return const Center(child: CircularProgressIndicator());
              return ListView(
                children: p.packages
                    .map((pkg) => ListTile(
                          leading: CircleAvatar(child: Text('#${pkg.displayOrder}')),
                          title: Text('${pkg.internalName}  —  ${pkg.marketingName}'),
                        ))
                    .toList(),
              );
            },
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('BASIC  —  Foundation Series'), findsOneWidget);
    expect(find.text('STANDARD  —  Signature'), findsOneWidget);
    expect(find.text('PREMIUM  —  Luxe'), findsOneWidget);
  });
}
