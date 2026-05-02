import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';
import 'package:admin/features/estimation_settings/presentation/screens/packages_list_screen.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets('PackagesListScreen renders the 3 packages from the API', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    adapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '''{
          "success": true,
          "data": [
            {"id":"u1","internalName":"BASIC","marketingName":"Foundation Series","displayOrder":10,"active":true},
            {"id":"u2","internalName":"STANDARD","marketingName":"Signature","displayOrder":20,"active":true},
            {"id":"u3","internalName":"PREMIUM","marketingName":"Luxe","displayOrder":30,"active":true}
          ]
        }''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final provider = EstimationPackagesProvider(
      service: EstimationPackageAdminService(dio: dio),
    );
    // runAsync escapes fakeAsync so real Dio futures resolve correctly.
    await tester.runAsync(() => provider.load());

    await tester.pumpWidget(MaterialApp(
      home: PackagesListScreen(providerOverride: provider),
    ));
    // Use pump() rather than pumpAndSettle() — pumpAndSettle loops forever on
    // screens that contain Tooltip widgets (they schedule recurring frames).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Estimation Packages'), findsOneWidget); // AppBar title
    expect(find.text('BASIC  —  Foundation Series'), findsOneWidget);
    expect(find.text('STANDARD  —  Signature'), findsOneWidget);
    expect(find.text('PREMIUM  —  Luxe'), findsOneWidget);
  });
}
