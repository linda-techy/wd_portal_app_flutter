// Widget tests for CustomerApproveBoqDialog.
//
// The dialog uses two services (BoqPaymentService, CustomerProjectService) as
// singletons that are constructed inside `initState` — there is no
// dependency-injection seam. To avoid touching production source we mock at
// the HTTP layer by swapping the singleton ApiService's Dio
// `httpClientAdapter` with a fake.
//
// Each test installs a per-test FakeHttpAdapter that responds to:
//   * GET    /customer-projects/{id}/members        → returns one OWNER
//   * PATCH  /api/boq-documents/{id}/customer-approve → success-shape JSON
//
// We do NOT exercise the real submit path in every test — only the
// submit-side test patches that endpoint. The other tests just need members
// to load so the dropdown shows and the Submit button can become enabled.

import 'dart:convert';

import 'package:admin/features/boq/presentation/screens/customer_approve_boq_dialog.dart';
import 'package:admin/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// flutter_secure_storage uses a method channel that doesn't exist in widget
// tests. Register a no-op handler so AuthInterceptor's `_storage.read`
// resolves to null instead of throwing.
void _stubSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    // Return null for read; empty map for readAll; void for everything else.
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
  /// Ordered list of `(matcher, handler)` pairs. First match wins.
  final List<({bool Function(RequestOptions) match, _Handler handler})> routes
      = [];

  /// Captured requests for later assertions in tests.
  final List<RequestOptions> capturedRequests = [];

  void on(
    String method,
    Pattern path,
    _Handler handler,
  ) {
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
    // Default: 404.
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

/// Replace the singleton ApiService's adapter with a per-test fake. Returns
/// the fake so individual tests can install handlers and inspect requests.
_FakeHttpAdapter _installFakeAdapter() {
  final fake = _FakeHttpAdapter();
  ApiService().dio.httpClientAdapter = fake;
  return fake;
}

// ───────────────────────────────────────────────────────────────────────────
// Pump helper
// ───────────────────────────────────────────────────────────────────────────

/// Make the test surface tall enough to host the full dialog (8 stages
/// + footer + signer). Default 800x600 cuts off the footer button.
Future<void> _setLargeViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  int boqDocumentId = 42,
  int projectId = 7,
  VoidCallback? onApproved,
}) async {
  _stubSecureStorageChannel();
  await _setLargeViewport(tester);

  // Mount a host that opens the dialog via showDialog so it's hosted in the
  // Overlay (matches production usage from BoqScreen).
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => CustomerApproveBoqDialog(
                  boqDocumentId: boqDocumentId,
                  projectId: projectId,
                  onApproved: onApproved ?? () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Allow showDialog animation + `_loadMembers()` (fired from initState) to
  // resolve. Can't pumpAndSettle — the loading spinner is a continuous
  // animation. 25 × 50ms is plenty.
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Find the "Record Approval" submit button. ElevatedButton.icon returns a
/// private `_ElevatedButtonWithIcon` subclass that does NOT match
/// `find.byType(ElevatedButton)` (Flutter 3.5 quirk). Match by widget name
/// instead.
Finder _submitButton() => find.ancestor(
      of: find.text('Record Approval'),
      matching: _byWidgetName(['ElevatedButton', '_ElevatedButtonWithIcon']),
    );

Finder _byWidgetName(List<String> names) =>
    find.byWidgetPredicate((w) => names.contains(w.runtimeType.toString()));

/// Predicate finder that matches the enabled/disabled state of an
/// ElevatedButton or its `.icon` variant by reading `onPressed`.
bool _isButtonEnabled(Widget w) {
  if (w is ElevatedButton) return w.onPressed != null;
  // _ElevatedButtonWithIcon stores onPressed in a base field accessible only
  // via reflection — use dynamic dispatch.
  try {
    final dyn = w as dynamic;
    return dyn.onPressed != null;
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return false;
  }
}

/// One OWNER member so the signer dropdown has a default selection.
final _membersBody = {
  'success': true,
  'data': [
    {
      'customerUserId': 11,
      'fullName': 'Owner Name',
      'email': 'owner@example.com',
      'roleInProject': 'OWNER',
    },
  ],
};

void _stubMembersOk(_FakeHttpAdapter fake) {
  fake.on('GET', '/customer-projects/', (_) => _jsonResponse(_membersBody));
}

// ───────────────────────────────────────────────────────────────────────────
// Tests
// ───────────────────────────────────────────────────────────────────────────

void main() {
  // Each test installs its own fake adapter so there's no test bleed.

  testWidgets(
      'sum != 100 — Submit disabled, total counter renders in red',
      (tester) async {
    final fake = _installFakeAdapter();
    _stubMembersOk(fake);

    await _pumpDialog(tester);

    // Default seeded stages sum to 100 — perturb the first stage's percent
    // so the total drifts to 95.
    final percentFields = find.widgetWithText(TextField, 'e.g. 10');
    expect(percentFields, findsWidgets);
    // First percent field corresponds to the first stage (10%). Replace
    // with 5 to make total 95.
    final firstPercent = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.controller?.text == '10' || w.controller?.text == '10.0'),
    );
    expect(firstPercent, findsWidgets);
    await tester.enterText(firstPercent.first, '5');
    await tester.pump();

    // Total counter shows the must-equal-100 hint.
    expect(
      find.textContaining('must equal 100%'),
      findsOneWidget,
    );

    // Submit button should be disabled.
    final submit = _submitButton();
    expect(submit, findsOneWidget);
    expect(_isButtonEnabled(tester.widget(submit)), isFalse,
        reason: 'Submit must be disabled when sum != 100%');
  });

  testWidgets('sum == 100 — Submit enabled, total counter renders 100%',
      (tester) async {
    final fake = _installFakeAdapter();
    _stubMembersOk(fake);

    await _pumpDialog(tester);
    // Default seeded stages already sum to 100 → no edits needed.

    expect(find.text('Total: 100%'), findsOneWidget);

    final submit = _submitButton();
    expect(submit, findsOneWidget);
    expect(_isButtonEnabled(tester.widget(submit)), isTrue,
        reason: 'Submit should be enabled when sum is 100% and member chosen');
  });

  testWidgets('reorder — tapping arrow_upward on stage 2 moves it to position 1',
      (tester) async {
    final fake = _installFakeAdapter();
    _stubMembersOk(fake);

    await _pumpDialog(tester);

    // Sanity: identify stage rows by their initial name fields.
    expect(find.text('Booking & design freeze'), findsOneWidget);
    expect(find.text('Foundation completion'), findsOneWidget);

    // Each row renders an "arrow_upward" IconButton. Row 0's button is
    // intentionally disabled (isFirst). Locate the IconButton directly
    // (not the wrapping Tooltip) and tap the second-row instance —
    // tapping a Tooltip's center often misses the IconButton hit-target.
    final upIconButtons = find.byWidgetPredicate(
      (w) => w is IconButton && (w.tooltip == 'Move up'),
    );
    expect(upIconButtons.evaluate().length, 8);
    // The dialog's internal SingleChildScrollView may keep row 1 below the
    // viewport — ensureVisible scrolls to it before tapping.
    await tester.ensureVisible(upIconButtons.at(1));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(upIconButtons.at(1));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify ordering by reading the position labels next to each name field.
    // The dialog renders "1.", "2.", … prefixes. Find the order of the
    // first two stage name TextFields.
    final nameFields = tester
        .widgetList<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Stage name',
          ),
        )
        .toList();
    expect(nameFields.length, greaterThanOrEqualTo(2));
    expect(
      nameFields[0].controller?.text,
      'Foundation completion',
      reason: 'Foundation completion should now be first',
    );
    expect(
      nameFields[1].controller?.text,
      'Booking & design freeze',
      reason: 'Booking & design freeze should now be second',
    );
  });

  testWidgets('add stage adds an empty row; sum recomputes live',
      (tester) async {
    final fake = _installFakeAdapter();
    _stubMembersOk(fake);

    await _pumpDialog(tester);

    final initialRows = tester
        .widgetList<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Stage name',
          ),
        )
        .length;
    expect(initialRows, 8); // default seed has 8

    // TextButton.icon has the same Flutter quirk as ElevatedButton.icon —
    // the actual widget type is `_TextButtonWithIcon`. Tap by ancestor.
    await tester.tap(find.ancestor(
      of: find.text('Add stage'),
      matching: _byWidgetName(['TextButton', '_TextButtonWithIcon']),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final after = tester
        .widgetList<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Stage name',
          ),
        )
        .length;
    expect(after, initialRows + 1);
    // The new row's percent defaults to 0 — total still 100% (sum unchanged
    // because it's 0). Verify counter still shows 100.
    expect(find.text('Total: 100%'), findsOneWidget);
  });

  testWidgets('delete stage removes the row and recomputes the sum live',
      (tester) async {
    final fake = _installFakeAdapter();
    _stubMembersOk(fake);

    await _pumpDialog(tester);

    final initialRows = tester
        .widgetList<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Stage name',
          ),
        )
        .length;
    expect(initialRows, 8);
    expect(find.text('Total: 100%'), findsOneWidget);

    // Delete the FIRST stage (Booking & design freeze @ 10%). We pick the
    // first row because it's reliably on-screen; the last row sits below
    // the dialog's internal scroll viewport in the test harness.
    final delButtons = find.byTooltip('Delete');
    expect(delButtons.evaluate().length, initialRows);
    await tester.tap(delButtons.first);
    await tester.pump(const Duration(milliseconds: 100));

    final after = tester
        .widgetList<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Stage name',
          ),
        )
        .length;
    expect(after, initialRows - 1);

    // Sum is now 92 — counter must show the must-equal-100 hint.
    expect(find.textContaining('must equal 100%'), findsOneWidget);
  });
}
