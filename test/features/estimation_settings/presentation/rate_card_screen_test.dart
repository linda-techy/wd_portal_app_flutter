import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/estimation_settings/data/services/estimation_package_admin_service.dart';
import 'package:admin/features/estimation_settings/data/services/package_rate_version_admin_service.dart';
import 'package:admin/features/estimation_settings/presentation/screens/rate_card_screen.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';
import 'package:admin/features/estimation_settings/providers/rate_versions_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  testWidgets(
      'RateCardScreen renders the package dropdown and 2 rate versions with ACTIVE badge',
      (tester) async {
    // --- packages mock ---
    final packagesDio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final packagesAdapter = MockDioAdapter();
    packagesDio.httpClientAdapter = packagesAdapter;
    packagesAdapter.mock('GET', '/api/estimation/packages', (_) {
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"p1","internalName":"BASIC","marketingName":"Foundation Series","displayOrder":10,"active":true}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    // --- rate versions mock ---
    final versionsDio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    final versionsAdapter = MockDioAdapter();
    versionsDio.httpClientAdapter = versionsAdapter;
    versionsAdapter.mock('GET', '/api/estimation/rate-versions', (_) {
      return ResponseBody.fromString(
        '''{"success":true,"data":[
          {"id":"v1","packageId":"p1","projectType":"NEW_BUILD","materialRate":1500,"labourRate":550,"overheadRate":300,"effectiveFrom":"2026-04-01","effectiveTo":null},
          {"id":"v0","packageId":"p1","projectType":"NEW_BUILD","materialRate":1420,"labourRate":520,"overheadRate":280,"effectiveFrom":"2026-01-01","effectiveTo":"2026-03-31"}
        ]}''',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    // Pre-populate both providers via runAsync (escapes fakeAsync so Dio futures resolve).
    final packagesProvider = EstimationPackagesProvider(
      service: EstimationPackageAdminService(dio: packagesDio),
    );
    await tester.runAsync(() => packagesProvider.load());

    final versionsProvider = RateVersionsProvider(
      service: PackageRateVersionAdminService(dio: versionsDio),
    );
    await tester.runAsync(() => versionsProvider.select(packageId: 'p1'));

    // Use a wider viewport so the 3-widget selector row doesn't overflow.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      home: RateCardScreen(
        packagesProviderOverride: packagesProvider,
        versionsProviderOverride: versionsProvider,
      ),
    ));
    // Use pump() rather than pumpAndSettle() — pumpAndSettle loops forever on
    // screens that contain Tooltip/Dropdown animation widgets.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Package Rate Card'), findsOneWidget); // AppBar title
    expect(find.text('2026-04-01 → present'), findsOneWidget);
    expect(find.text('2026-01-01 → 2026-03-31'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });
}
