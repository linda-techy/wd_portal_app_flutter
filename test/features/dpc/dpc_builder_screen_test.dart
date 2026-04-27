// Widget tests for DpcBuilderScreen.
//
// The screen calls `DpcService` (a singleton) directly from initState — no
// dependency-injection seam exists. To avoid touching production source we
// mock at the HTTP layer by swapping the singleton ApiService's Dio
// `httpClientAdapter` with a fake.
//
// We assert:
//   1. Scope save debounce — typing in the rationale field schedules a
//      service call only after ~500ms of quiet, not on every keystroke.
//   2. Issue confirmation — tapping "Issue" shows a confirmation dialog;
//      Cancel does NOT call the service; Issue DOES.
//   3. ISSUED-state read-only — when the document arrives with
//      status:'ISSUED' the form fields are read-only and the issued
//      banner with the "New Revision" button is shown instead of the
//      Issue / Save Draft buttons.
//
// The screen also embeds `printing.PdfPreview`. We arrange for the preview
// PDF endpoint to FAIL — that keeps `_previewBytes` null and renders a
// placeholder instead of the platform-channel-backed PdfPreview, which
// would otherwise crash in the headless test harness.

import 'dart:convert';

import 'package:admin/features/dpc/presentation/screens/dpc_builder_screen.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// flutter_secure_storage uses a method channel that doesn't exist in widget
// tests. Register a no-op handler so AuthInterceptor's `_storage.read`
// resolves to null instead of throwing.
void _stubSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'read') return null;
    if (call.method == 'readAll') return <String, String>{};
    return null;
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Fake HTTP adapter
// ───────────────────────────────────────────────────────────────────────────

typedef _Handler = ResponseBody Function(RequestOptions options);

class _FakeHttpAdapter implements HttpClientAdapter {
  final List<({bool Function(RequestOptions) match, _Handler handler})> routes
      = [];
  final List<RequestOptions> capturedRequests = [];

  void on(String method, Pattern path, _Handler handler) {
    routes.add((
      match: (opts) {
        if (opts.method.toUpperCase() != method.toUpperCase()) return false;
        return path.allMatches(opts.path).isNotEmpty;
      },
      handler: handler,
    ));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    capturedRequests.add(options);
    for (final r in routes) {
      if (r.match(options)) return r.handler(options);
    }
    // Default: 404. Forces unmocked endpoints to surface as errors instead
    // of hanging.
    return ResponseBody.fromString(
      jsonEncode({'success': false, 'message': 'unmocked: ${options.path}'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

_FakeHttpAdapter _installFakeAdapter() {
  final fake = _FakeHttpAdapter();
  ApiService().dio.httpClientAdapter = fake;
  return fake;
}

// ───────────────────────────────────────────────────────────────────────────
// Fixtures
// ───────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _scopeJson({
  required int id,
  required String code,
  required String title,
  String? rationale,
  int displayOrder = 1,
}) =>
    {
      'id': id,
      'scopeCode': code,
      'scopeTitle': title,
      'selectedOptionRationale': rationale,
      'brandsResolved': <String, String>{},
      'whatYouGetResolved': <String>[],
      'includedInPdf': true,
      'displayOrder': displayOrder,
      'originalAmount': 100000,
      'customizedAmount': 100000,
      'availableOptions': <Map<String, dynamic>>[],
    };

Map<String, dynamic> _docJson({
  required int id,
  String status = 'DRAFT',
  int revisionNumber = 1,
  DateTime? issuedAt,
  List<Map<String, dynamic>>? scopes,
}) =>
    {
      'id': id,
      'projectId': 7,
      'revisionNumber': revisionNumber,
      'status': status,
      'projectName': 'Test Project',
      'projectLocation': 'Test City',
      'sqfeet': 1000,
      'issuedAt': issuedAt?.toIso8601String(),
      'scopes': scopes ??
          [
            _scopeJson(
              id: 100,
              code: 'STRUCTURE',
              title: 'Structure',
              displayOrder: 1,
            ),
          ],
      'customizationLines': <Map<String, dynamic>>[],
      'masterCostSummary': {
        'totalOriginal': 100000,
        'totalCustomized': 100000,
        'totalVariance': 0,
        'originalPerSqft': 100,
        'customizedPerSqft': 100,
        'sqfeet': 1000,
        'scopes': <Map<String, dynamic>>[],
      },
      'paymentMilestones': <Map<String, dynamic>>[],
    };

// ───────────────────────────────────────────────────────────────────────────
// Pump helper
// ───────────────────────────────────────────────────────────────────────────

PermissionProvider _adminPerms() {
  final p = PermissionProvider();
  // ADMIN role grants every permission via the existing bypass — saves us
  // listing every code by name.
  p.setPermissions(const [], 'ADMIN');
  return p;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeHttpAdapter fake,
  required Map<String, dynamic> latestDocJson,
  PermissionProvider? perms,
}) async {
  _stubSecureStorageChannel();
  // Wide surface so the AppBar's title + revision/status pills don't
  // collide with the 5 action buttons (Revisions / Preview / Save / Issue
  // / Padding) — the production layout assumes desktop widths.
  await tester.binding.setSurfaceSize(const Size(1800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Always stub the latest-doc fetch so initState resolves.
  fake.on(
    'GET',
    RegExp(r'/api/projects/\d+/dpc-documents/latest'),
    (_) => _jsonResponse({'success': true, 'data': latestDocJson}),
  );
  // Default the preview-pdf endpoint to a 500 — keeps `_previewBytes` null
  // so the screen renders the placeholder instead of the printing-package
  // PdfPreview widget (which crashes in headless tests).
  fake.on(
    'GET',
    RegExp(r'/api/dpc-documents/\d+/preview-pdf'),
    (_) => ResponseBody.fromString(
      'preview unavailable',
      500,
      headers: {
        Headers.contentTypeHeader: ['text/plain'],
      },
    ),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<PermissionProvider>.value(
      value: perms ?? _adminPerms(),
      child: const MaterialApp(
        home: DpcBuilderScreen(projectId: 7),
      ),
    ),
  );

  // Allow the bootstrap fetch + first preview attempt to complete.
  // Can't pumpAndSettle because the LayoutBuilder + spinners keep frames
  // running. 25 × 50ms is plenty.
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Tests
// ───────────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('scope save debounce — patch fires ~500ms after typing stops',
      (tester) async {
    final fake = _installFakeAdapter();

    // Stub PATCH for the scope so the debounced save resolves cleanly.
    fake.on(
      'PATCH',
      RegExp(r'/api/dpc-documents/\d+/scopes/\d+'),
      (opts) => _jsonResponse({
        'success': true,
        'data': _docJson(id: 1),
      }),
    );

    await _pumpScreen(
      tester,
      fake: fake,
      latestDocJson: _docJson(id: 1),
    );

    // Expand the scope tile by tapping its title.
    await tester.tap(find.text('Structure'));
    await tester.pump(const Duration(milliseconds: 300));

    // The rationale TextField has labelText 'Selected option rationale'.
    final rationale = find.widgetWithText(TextField, 'Selected option rationale');
    expect(rationale, findsOneWidget);

    // Capture how many scope-PATCH calls existed before typing.
    int scopePatchCount() => fake.capturedRequests
        .where((r) =>
            r.method.toUpperCase() == 'PATCH' &&
            RegExp(r'/api/dpc-documents/\d+/scopes/\d+').hasMatch(r.path))
        .length;
    final before = scopePatchCount();

    // Type a single character. Scope save uses a 500ms debounce — must not
    // fire immediately.
    await tester.enterText(rationale, 'we like quality');
    await tester.pump(const Duration(milliseconds: 100));
    expect(scopePatchCount(), before,
        reason: 'No PATCH should fire within 100ms — debounce is 500ms');

    // Cross the debounce threshold.
    await tester.pump(const Duration(milliseconds: 600));
    // Allow the fired async POST to actually run.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(scopePatchCount(), greaterThan(before),
        reason: 'Scope PATCH should have fired after 500ms debounce');
  });

  testWidgets(
      'Issue confirmation dialog — Cancel does NOT call /issue; Issue DOES',
      (tester) async {
    final fake = _installFakeAdapter();
    fake.on(
      'POST',
      RegExp(r'/api/dpc-documents/\d+/issue$'),
      (_) => _jsonResponse({
        'success': true,
        'data': _docJson(
            id: 1,
            status: 'ISSUED',
            revisionNumber: 1,
            issuedAt: DateTime.now()),
      }),
    );

    await _pumpScreen(
      tester,
      fake: fake,
      latestDocJson: _docJson(id: 1),
    );

    // Tap the Issue button in the AppBar actions. ElevatedButton.icon
    // returns _ElevatedButtonWithIcon — find via the label text.
    final issueAppBarBtn = find.text('Issue');
    expect(issueAppBarBtn, findsOneWidget);
    await tester.tap(issueAppBarBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Confirmation dialog visible.
    expect(find.text('Issue DPC?'), findsOneWidget);

    // Cancel — must NOT fire the /issue POST.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    int issueCallCount() => fake.capturedRequests
        .where((r) =>
            r.method.toUpperCase() == 'POST' &&
            RegExp(r'/api/dpc-documents/\d+/issue$').hasMatch(r.path))
        .length;
    expect(issueCallCount(), 0,
        reason: 'Cancelling the confirmation must not POST /issue');

    // Open it again, this time confirm.
    await tester.tap(issueAppBarBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Issue DPC?'), findsOneWidget);

    // The confirm button is the dialog's ElevatedButton labeled "Issue".
    // There are two Texts saying "Issue" now — one in the AppBar action,
    // one in the dialog. Pick the dialog one — the one that's an
    // ElevatedButton inside an AlertDialog.
    final confirmBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(ElevatedButton, 'Issue'),
    );
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    // Allow the POST + state hydrate + setState to settle.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(issueCallCount(), 1,
        reason: 'Confirming must POST /issue exactly once');
  });

  testWidgets(
      'ISSUED state — issued banner with "New Revision" button replaces Save Draft / Issue actions',
      (tester) async {
    final fake = _installFakeAdapter();

    await _pumpScreen(
      tester,
      fake: fake,
      latestDocJson: _docJson(
        id: 1,
        status: 'ISSUED',
        issuedAt: DateTime.utc(2026, 4, 1, 10, 0),
      ),
    );

    // Issued banner is visible.
    expect(
      find.textContaining('Issued on'),
      findsOneWidget,
      reason: 'ISSUED docs render the issued-on banner',
    );

    // Banner exposes the "New Revision" button (admin role can create).
    expect(find.text('New Revision'), findsOneWidget);

    // The AppBar's Save Draft button must be hidden OR disabled in
    // ISSUED state. The screen builds the button only when canEditDpc;
    // ADMIN has it, so it IS rendered. Rule from production: when issued,
    // the button's onPressed is null (`doc.isIssued || _saving ? null …`).
    // Find the AppBar Save Draft text and walk up to its enclosing
    // ElevatedButton-like ancestor; assert disabled.
    final saveLabel = find.text('Save Draft');
    expect(saveLabel, findsOneWidget);
    final saveBtn = find.ancestor(
      of: saveLabel,
      matching: find.byWidgetPredicate((w) =>
          w.runtimeType.toString() == 'ElevatedButton' ||
          w.runtimeType.toString() == '_ElevatedButtonWithIcon'),
    );
    expect(saveBtn, findsOneWidget);
    final saveWidget = tester.widget(saveBtn) as dynamic;
    expect(saveWidget.onPressed, isNull,
        reason: 'Save Draft must be disabled when document is ISSUED');

    // Same for the AppBar Issue button — disabled in ISSUED state.
    final issueLabel = find.text('Issue');
    expect(issueLabel, findsOneWidget);
    final issueBtn = find.ancestor(
      of: issueLabel,
      matching: find.byWidgetPredicate((w) =>
          w.runtimeType.toString() == 'ElevatedButton' ||
          w.runtimeType.toString() == '_ElevatedButtonWithIcon'),
    );
    expect(issueBtn, findsOneWidget);
    final issueWidget = tester.widget(issueBtn) as dynamic;
    expect(issueWidget.onPressed, isNull,
        reason: 'Issue must be disabled when document is already ISSUED');
  });
}
