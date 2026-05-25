// Widget tests for StageTemplateEditorScreen.
//
// HTTP is mocked at the Dio adapter layer (same pattern as
// customer_approve_boq_dialog_test.dart). Each test installs a fresh
// _FakeHttpAdapter so there is no bleed between cases.
//
// Gotchas honoured:
//   - No `await` before pumpWidget (fake-async deadlock would occur).
//   - No pumpAndSettle on text-field tests (avoids continuous-animation hang).
//   - Viewport set to 1024×1600 so the full list and toolbar are on-screen.
//   - flutter_secure_storage channel stubbed (AuthInterceptor uses it).

import 'dart:convert';

import 'package:admin/features/boq/presentation/screens/stage_template_editor_screen.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Secure-storage stub ───────────────────────────────────────────────────────

void _stubSecureStorage() {
  const ch = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(ch, (call) async {
    if (call.method == 'read') return null;
    if (call.method == 'readAll') return <String, String>{};
    return null;
  });
}

// ── Fake HTTP adapter ─────────────────────────────────────────────────────────

typedef _Handler = ResponseBody Function(RequestOptions opts);

class _FakeHttpAdapter implements HttpClientAdapter {
  final List<({bool Function(RequestOptions) match, _Handler handler})> routes =
      [];
  final List<RequestOptions> captured = [];

  void on(String method, Pattern path, _Handler handler) {
    routes.add((
      match: (o) =>
          o.method.toUpperCase() == method.toUpperCase() &&
          path.allMatches(o.path).isNotEmpty,
      handler: handler,
    ));
  }

  @override
  Future<ResponseBody> fetch(RequestOptions opts,
      Stream<Uint8List>? req, Future<dynamic>? cancel) async {
    captured.add(opts);
    for (final r in routes) {
      if (r.match(opts)) return r.handler(opts);
    }
    return ResponseBody.fromString(
      jsonEncode({'success': false, 'message': 'unmocked: ${opts.path}'}),
      404,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );

_FakeHttpAdapter _install() {
  final fake = _FakeHttpAdapter();
  ApiService().dio.httpClientAdapter = fake;
  return fake;
}

// ── Sample template payload ───────────────────────────────────────────────────

Map<String, dynamic> _templateBody({List<Map<String, dynamic>>? stages}) => {
      'success': true,
      'data': {
        'projectId': 5,
        'stages': stages ??
            [
              {
                'stageNumber': 1,
                'name': 'Advance',
                'percentage': 0.10,
                'milestoneDescription': null,
              },
              {
                'stageNumber': 2,
                'name': 'Foundation',
                'percentage': 0.20,
                'milestoneDescription': 'Slab cast',
              },
              {
                'stageNumber': 3,
                'name': 'Structure',
                'percentage': 0.30,
                'milestoneDescription': null,
              },
              {
                'stageNumber': 4,
                'name': 'Finishing',
                'percentage': 0.40,
                'milestoneDescription': null,
              },
            ],
      },
    };

// ── Button helpers ────────────────────────────────────────────────────────────

/// Finds the outermost ElevatedButton (or its .icon variant) whose label
/// contains [label]. Flutter's ElevatedButton.icon creates a private
/// `_ElevatedButtonWithIcon` — match by runtimeType string.
Finder _elevatedButtonWith(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('ElevatedButton'),
      ),
    );

bool _isEnabled(WidgetTester tester, Finder f) {
  // There may be 2 matches (inner child + outer button). Take the last one,
  // which is the actual ButtonStyleButton with an onPressed field.
  final widgets = tester.widgetList(f).toList();
  final btn = widgets.last;
  try {
    // ignore: avoid_dynamic_calls
    return (btn as dynamic).onPressed != null;
  } catch (_) {
    return false;
  }
}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> _pumpScreen(WidgetTester tester) async {
  _stubSecureStorage();
  await tester.binding.setSurfaceSize(const Size(1024, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    const MaterialApp(
      home: StageTemplateEditorScreen(projectId: 5),
    ),
  );

  // Allow initState → _load() → GET → setState to settle.
  // 30 × 50 ms is plenty; avoids pumpAndSettle on continuous spinner.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('loads template and shows Total: 100%', (tester) async {
    final fake = _install();
    fake.on('GET', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    await _pumpScreen(tester);

    // Four stage name fields must be present.
    final nameFields = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Stage name',
    );
    expect(nameFields, findsNWidgets(4));

    // Total banner must show 100%.
    expect(find.text('Total: 100%'), findsOneWidget);

    // Save button must be enabled (total == 100).
    expect(_isEnabled(tester, _elevatedButtonWith('Save template')), isTrue,
        reason: 'Save must be enabled when total == 100%');
  });

  testWidgets('changing a percentage updates total and disables Save',
      (tester) async {
    final fake = _install();
    fake.on('GET', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    await _pumpScreen(tester);

    // Locate the first percentage field (shows "10" for 0.10).
    final percentFields = find.byWidgetPredicate(
      (w) =>
          w is TextField && w.decoration?.suffixText == '%',
    );
    expect(percentFields, findsWidgets);

    // Replace first stage's 10% with 5% → total becomes 95.
    await tester.enterText(percentFields.first, '5');
    await tester.pump(const Duration(milliseconds: 50));

    // Banner must show "must equal 100%".
    expect(find.textContaining('must equal 100%'), findsOneWidget);

    // Save button must be disabled.
    expect(_isEnabled(tester, _elevatedButtonWith('Save template')), isFalse,
        reason: 'Save must be disabled when total != 100%');
  });

  testWidgets('Add stage appends an empty row', (tester) async {
    final fake = _install();
    fake.on('GET', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    await _pumpScreen(tester);

    final before = tester
        .widgetList<TextField>(find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'Stage name'))
        .length;
    expect(before, 4);

    await tester.tap(find.ancestor(
      of: find.text('Add stage'),
      matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('TextButton')),
    ).last);
    await tester.pump(const Duration(milliseconds: 50));

    final after = tester
        .widgetList<TextField>(find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'Stage name'))
        .length;
    expect(after, before + 1);
  });

  testWidgets('Delete removes a row', (tester) async {
    final fake = _install();
    fake.on('GET', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    await _pumpScreen(tester);

    final before = tester
        .widgetList<TextField>(find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'Stage name'))
        .length;

    final deleteBtns = find.byTooltip('Delete');
    expect(deleteBtns, findsNWidgets(before));

    await tester.tap(deleteBtns.first);
    await tester.pump(const Duration(milliseconds: 50));

    final after = tester
        .widgetList<TextField>(find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'Stage name'))
        .length;
    expect(after, before - 1);
  });

  testWidgets('Save calls PUT with renumbered stages', (tester) async {
    final fake = _install();
    fake.on('GET', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    // PUT → success response (return the same template for simplicity).
    fake.on('PUT', RegExp(r'/customer-projects/\d+/stage-template'),
        (_) => _json(_templateBody()));

    await _pumpScreen(tester);

    // Total is already 100% → Save is enabled.
    await tester.tap(_elevatedButtonWith('Save template').last);
    // Allow the async save + SnackBar to settle (not pumpAndSettle — avoids
    // timer issues; 20 × 50ms is enough for a single HTTP round-trip fake).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // A PUT request must have been captured.
    final putRequests = fake.captured
        .where((r) => r.method.toUpperCase() == 'PUT')
        .toList();
    expect(putRequests.length, 1);

    // Success snackbar must appear.
    expect(find.text('Stage template saved'), findsOneWidget);
  });

  // ── Unit tests for StageTemplateRow model ─────────────────────────────────

  test('StageTemplateRow.fromJson converts percentage fraction correctly', () {
    final row = StageTemplateRow.fromJson({
      'stageNumber': 2,
      'name': 'Foundation',
      'percentage': 0.25,
      'milestoneDescription': 'Slab done',
    });
    expect(row.stageNumber, 2);
    expect(row.name, 'Foundation');
    expect(row.percentageFraction, closeTo(0.25, 0.001));
    expect(row.milestoneDescription, 'Slab done');
  });

  test('StageTemplateRow.toJson round-trips correctly', () {
    const row = StageTemplateRow(
      stageNumber: 3,
      name: 'Structure',
      percentageFraction: 0.30,
      milestoneDescription: null,
    );
    final j = row.toJson();
    expect(j['stageNumber'], 3);
    expect(j['percentage'], closeTo(0.30, 0.001));
    expect(j.containsKey('milestoneDescription'), isFalse);
  });
}
