import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_template_picker_dialog.dart';

import '../../../../test_helpers/mock_dio_adapter.dart';

WbsTemplateService _serviceWithTemplates(String body) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  final adapter = MockDioAdapter();
  dio.httpClientAdapter = adapter;
  adapter.mock('GET', '/api/wbs/templates', (_) {
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  });
  return WbsTemplateService(dio: dio);
}

void main() {
  // Set a wide viewport for all tests; the dialog is 520px wide.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders only active templates of the requested project type',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final service = _serviceWithTemplates(
      '['
      // Should be rendered: residential + active.
      '{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
      '"name":"Residential v1","version":1,"isActive":true,"phases":[]},'
      // Should be filtered out: wrong type.
      '{"id":2,"code":"COM","projectType":"COMMERCIAL",'
      '"name":"Commercial v1","version":1,"isActive":true,"phases":[]},'
      // Should be filtered out: residential but inactive.
      '{"id":3,"code":"RES","projectType":"RESIDENTIAL",'
      '"name":"Residential v0","version":0,"isActive":false,"phases":[]}'
      ']',
    );

    WbsTemplatePickerResult? captured;
    bool dialogReturned = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await WbsTemplatePickerDialog.show(
                  ctx,
                  projectType: WbsProjectType.residential,
                  defaultFloors: 2,
                  serviceOverride: service,
                );
                dialogReturned = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pump(); // build dialog
    await tester.pump(); // post-frame load
    // Allow microtasks/futures to drain.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Materialize WBS from template'), findsOneWidget);
    expect(find.text('Residential v1'), findsOneWidget);
    expect(find.text('Commercial v1'), findsNothing);
    expect(find.text('Residential v0'), findsNothing);

    // Floors field defaulted to 2.
    expect(find.widgetWithText(TextFormField, '2'), findsOneWidget);

    // Skip returns null.
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(dialogReturned, isTrue);
    expect(captured, isNull);
  });

  testWidgets('Materialize returns the selected templateId + floor count',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final service = _serviceWithTemplates(
      '['
      '{"id":7,"code":"RES","projectType":"RESIDENTIAL",'
      '"name":"Residential v1","version":1,"isActive":true,"phases":[]}'
      ']',
    );

    WbsTemplatePickerResult? captured;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await WbsTemplatePickerDialog.show(
                  ctx,
                  projectType: WbsProjectType.residential,
                  defaultFloors: 3,
                  serviceOverride: service,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Single template auto-selects → Materialize is enabled.
    final materializeBtn = find.widgetWithText(FilledButton, 'Materialize');
    expect(materializeBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(materializeBtn).onPressed, isNotNull);

    await tester.tap(materializeBtn);
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.templateId, 7);
    expect(captured!.floorCount, 3);
  });

  testWidgets('floor input rejects non-numeric / out-of-range values',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final service = _serviceWithTemplates(
      '['
      '{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
      '"name":"Residential v1","version":1,"isActive":true,"phases":[]}'
      ']',
    );

    WbsTemplatePickerResult? captured;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await WbsTemplatePickerDialog.show(
                  ctx,
                  projectType: WbsProjectType.residential,
                  defaultFloors: 1,
                  serviceOverride: service,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Type "99" — out of range (max 20).
    final floorsField = find.byType(TextFormField);
    await tester.enterText(floorsField, '99');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Materialize'));
    await tester.pump();

    // Validator should kick in; dialog stays open.
    expect(find.text('Materialize WBS from template'), findsOneWidget);
    expect(find.textContaining('between'), findsOneWidget);
    expect(captured, isNull);
  });

  test('mapCustomerProjectTypeToWbs maps known forms and returns null otherwise',
      () {
    expect(mapCustomerProjectTypeToWbs('residential_construction'),
        WbsProjectType.residential);
    expect(mapCustomerProjectTypeToWbs('commercial_construction'),
        WbsProjectType.commercial);
    expect(mapCustomerProjectTypeToWbs('industrial_construction'),
        WbsProjectType.commercial);
    expect(mapCustomerProjectTypeToWbs('interior_work'),
        WbsProjectType.interiorFitout);
    expect(mapCustomerProjectTypeToWbs('renovation_remodeling'),
        WbsProjectType.renovation);

    // Unmapped → null (caller skips the picker silently).
    expect(mapCustomerProjectTypeToWbs('vastu_consultation'), isNull);
    expect(mapCustomerProjectTypeToWbs('smart_home_integration'), isNull);
    expect(mapCustomerProjectTypeToWbs(''), isNull);
    expect(mapCustomerProjectTypeToWbs(null), isNull);
  });
}
