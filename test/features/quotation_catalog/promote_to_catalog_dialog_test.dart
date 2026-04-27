// Widget tests for PromoteToCatalogDialog.
//
// The dialog instantiates `QuotationCatalogService()` (a singleton) inside
// initState. To avoid touching production source we replace the singleton
// `ApiService`'s Dio `httpClientAdapter` with a fake that returns a
// canned `promoteItemToCatalog` response. The submit-success test then
// asserts that:
//   * the call was made,
//   * the request body contains the exact code/name/price the user
//     entered (i.e. the dialog forwarded them through the service).
//
// We cover:
//   1. Code derivation — typing into the name field auto-fills the code
//      with the same uppercase-dash-separated form the backend uses.
//   2. Validation — empty name keeps Submit disabled; valid name+price
//      enables it.
//   3. Submit calls `promoteItemToCatalog` with the entered values.

import 'dart:convert';

import 'package:admin/features/quotation_catalog/presentation/screens/promote_to_catalog_dialog.dart';
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
// Pump helper
// ───────────────────────────────────────────────────────────────────────────

Future<void> _pumpDialog(
  WidgetTester tester, {
  int itemId = 7,
  String sourceDescription = 'Premium Hardwood Flooring',
  double sourceUnitPrice = 1234.56,
}) async {
  _stubSecureStorageChannel();
  await tester.binding.setSurfaceSize(const Size(900, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<dynamic>(
                context: ctx,
                builder: (_) => PromoteToCatalogDialog(
                  itemId: itemId,
                  sourceDescription: sourceDescription,
                  sourceUnitPrice: sourceUnitPrice,
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
  await tester.pumpAndSettle();
}

// ───────────────────────────────────────────────────────────────────────────
// Tests
// ───────────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
      'code field is auto-filled from the source description on initState',
      (tester) async {
    _installFakeAdapter();
    await _pumpDialog(
      tester,
      sourceDescription: 'Premium Hardwood Flooring (Oak)',
    );

    // The dialog's _deriveCode uppercases, replaces non-alphanumerics with
    // dashes, collapses dashes, and strips edge dashes:
    //   'Premium Hardwood Flooring (Oak)' →
    //   'PREMIUM-HARDWOOD-FLOORING-OAK'
    final codeField = find.widgetWithText(
      TextFormField,
      'PREMIUM-HARDWOOD-FLOORING-OAK',
    );
    expect(codeField, findsOneWidget,
        reason:
            'Code field should be pre-filled with the derived code on open');
  });

  testWidgets(
      'code derivation handles punctuation and whitespace identical to the backend',
      (tester) async {
    _installFakeAdapter();
    await _pumpDialog(
      tester,
      sourceDescription: '  hello,   world!! ',
    );

    // Expected derivation: 'HELLO-WORLD'
    expect(find.widgetWithText(TextFormField, 'HELLO-WORLD'), findsOneWidget);
  });

  testWidgets(
      'empty name surfaces "Name is required" via the form validator',
      (tester) async {
    // Install a fake that will SWALLOW any unintended POST. We don't
    // expect the form to submit when the name is empty — but we install
    // a successful response just in case so the test doesn't leak
    // pending timers if the validator misbehaves.
    final fake = _installFakeAdapter();
    fake.on(
      'POST',
      RegExp(r'/leads/quotations/items/\d+/promote-to-catalog'),
      (_) => _jsonResponse({
        'success': true,
        'data': {
          'id': 1,
          'code': 'X',
          'name': 'X',
          'defaultUnitPrice': 0.0,
        },
      }),
    );

    await _pumpDialog(
      tester,
      sourceDescription: 'Some item',
      sourceUnitPrice: 100,
    );

    // The dialog has 4 TextFormFields in order: Code, Name, Unit, Price.
    final formFields = find.byType(TextFormField);
    expect(formFields, findsNWidgets(4));
    final nameField = formFields.at(1);

    // Clear the name to make the form invalid.
    await tester.enterText(nameField, '');
    await tester.pump();

    // Tap Promote — validator must block the submit and render the
    // "Name is required" inline message.
    final promoteBtn = find.widgetWithText(ElevatedButton, 'Promote');
    expect(promoteBtn, findsOneWidget);
    await tester.tap(promoteBtn);
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget,
        reason: 'Validator must surface "Name is required" when blank');

    // Sanity-check: the validator was the gate — no POST should have
    // fired against the catalog endpoint.
    final promoteCalls = fake.capturedRequests
        .where((r) => r.path.contains('/promote-to-catalog'))
        .length;
    expect(promoteCalls, 0,
        reason: 'Submit must not call the service when the form is invalid');
  });

  testWidgets(
      'valid name+price clears the validator error so submit can proceed',
      (tester) async {
    final fake = _installFakeAdapter();
    fake.on(
      'POST',
      RegExp(r'/leads/quotations/items/\d+/promote-to-catalog'),
      (_) => _jsonResponse({
        'success': true,
        'data': {
          'id': 5,
          'code': 'Y',
          'name': 'Y',
          'defaultUnitPrice': 1.0,
        },
      }),
    );
    await _pumpDialog(
      tester,
      sourceDescription: 'X',
      sourceUnitPrice: 1,
    );

    // Seed values are already valid — typing a new valid name keeps it so.
    final formFields = find.byType(TextFormField);
    final nameField = formFields.at(1);
    await tester.enterText(nameField, 'Valid name');
    await tester.pump();

    // Tap Promote — submit should fire (we mocked the response). After
    // submit the dialog calls Navigator.pop and the request count goes
    // to 1.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Promote'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Name is required'), findsNothing);
    final promoteCalls = fake.capturedRequests
        .where((r) => r.path.contains('/promote-to-catalog'))
        .length;
    expect(promoteCalls, 1,
        reason: 'Valid form should trigger exactly one service call');
  });

  testWidgets(
      'tapping Promote with valid data calls promoteItemToCatalog with entered values',
      (tester) async {
    final fake = _installFakeAdapter();
    fake.on(
      'POST',
      RegExp(r'/leads/quotations/items/\d+/promote-to-catalog'),
      (_) => _jsonResponse({
        'success': true,
        'data': {
          'id': 1234,
          'code': 'NEW-LINE',
          'name': 'New Line',
          'description': null,
          'category': null,
          'unit': 'sqft',
          'defaultUnitPrice': 250.0,
          'timesUsed': 0,
          'isActive': true,
          'createdAt': null,
          'updatedAt': null,
        },
      }),
    );

    await _pumpDialog(
      tester,
      itemId: 99,
      sourceDescription: 'Old description',
      sourceUnitPrice: 250,
    );

    // Override name to a new value.
    final nameField = find.widgetWithText(TextFormField, 'Old description');
    await tester.enterText(nameField, 'New Line');
    await tester.pump();

    // Override code to an explicit value.
    final codeField = find.byWidgetPredicate(
      (w) =>
          w is TextFormField && w.controller?.text.contains('OLD-DESCRIPTION') == true,
    );
    expect(codeField, findsOneWidget);
    await tester.enterText(codeField, 'NEW-LINE');
    await tester.pump();

    // Tap Promote.
    final promoteBtn = find.widgetWithText(ElevatedButton, 'Promote');
    await tester.tap(promoteBtn);
    // Allow the async service call to complete + dialog to dismiss.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify the request fired with the right body.
    final promoteRequests = fake.capturedRequests
        .where((r) => r.path.contains('/promote-to-catalog'))
        .toList();
    expect(promoteRequests, hasLength(1),
        reason: 'Service should be called exactly once');

    final body = promoteRequests.single.data as Map<String, dynamic>;
    expect(body['code'], 'NEW-LINE');
    expect(body['name'], 'New Line');
    expect(body['defaultUnitPrice'], 250.0);
    // unit defaults to null (we never typed in the unit field).
    expect(body['unit'], isNull);
    // category defaults to null.
    expect(body['category'], isNull);

    // Path includes itemId.
    expect(promoteRequests.single.path,
        '/leads/quotations/items/99/promote-to-catalog');
  });
}
