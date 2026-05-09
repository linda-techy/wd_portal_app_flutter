import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/providers/pending_sync_provider.dart';
import 'package:admin/screens/sync/pending_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// In-memory provider stub: no Drift, no Dio. We feed pre-canned state.
class _StubProvider extends ChangeNotifier implements PendingSyncProvider {
  _StubProvider({
    List<OutboxEntry> queued = const [],
    List<OutboxEntry> issues = const [],
    bool isSyncing = false,
  })  : _queued = queued,
        _issues = issues,
        _isSyncing = isSyncing;

  final List<OutboxEntry> _queued;
  final List<OutboxEntry> _issues;
  bool _isSyncing;

  @override
  int get pendingCount => _queued.length;
  @override
  List<OutboxEntry> get queued => _queued;
  @override
  List<OutboxEntry> get issues => _issues;
  @override
  bool get isSyncing => _isSyncing;
  @override
  Future<void> syncNow() async {
    _isSyncing = true;
    notifyListeners();
  }

  @override
  Future<void> retryPermanent(int id) async {}
  @override
  Future<void> discardPermanent(int id) async {}
  // ignore: no_runtimetype_tostring
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrap(PendingSyncProvider p) => MaterialApp(
      home: ChangeNotifierProvider<PendingSyncProvider>.value(
        value: p,
        child: const PendingSyncScreen(),
      ),
    );

void main() {
  testWidgets('Empty state — Queued tab shows "All synced"', (t) async {
    await t.pumpWidget(_wrap(_StubProvider()));
    await t.pump();
    expect(find.text('All synced — nothing waiting'), findsOneWidget);
  });

  testWidgets('Empty state — Issues tab shows "No issues"', (t) async {
    await t.pumpWidget(_wrap(_StubProvider()));
    await t.tap(find.text('Issues'));
    await t.pumpAndSettle();
    expect(find.text('No issues'), findsOneWidget);
  });

  testWidgets('Queued items rendered in Queued tab', (t) async {
    final entry = OutboxEntry(
      id: 1, clientUuid: 'u1', mutationType: 'DELAY_LOG_CREATE',
      projectId: 9, taskId: null, payloadJson: '{}',
      photoFilePath: null, latitude: null, longitude: null,
      gpsAccuracyMeters: null, capturedAt: null, state: 'PENDING',
      attempts: 0, nextRetryAt: null, lastErrorMessage: null,
      lastErrorStatus: null,
      createdAt: DateTime.utc(2026, 5, 7), updatedAt: DateTime.utc(2026, 5, 7),
    );
    await t.pumpWidget(_wrap(_StubProvider(queued: [entry])));
    await t.pump();
    expect(find.textContaining('DELAY_LOG_CREATE'), findsOneWidget);
  });

  testWidgets('Issues tab shows error + Retry/Discard', (t) async {
    final entry = OutboxEntry(
      id: 2, clientUuid: 'u2', mutationType: 'SITE_REPORT_CREATE',
      projectId: 9, taskId: null, payloadJson: '{}',
      photoFilePath: null, latitude: null, longitude: null,
      gpsAccuracyMeters: null, capturedAt: null, state: 'PERMANENT_FAILURE',
      attempts: 5, nextRetryAt: null,
      lastErrorMessage: 'Bad payload', lastErrorStatus: 422,
      createdAt: DateTime.utc(2026, 5, 7), updatedAt: DateTime.utc(2026, 5, 7),
    );
    await t.pumpWidget(_wrap(_StubProvider(issues: [entry])));
    await t.tap(find.text('Issues'));
    await t.pumpAndSettle();
    expect(find.textContaining('Bad payload'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('Sync now button visible at top of Queued tab', (t) async {
    await t.pumpWidget(_wrap(_StubProvider()));
    await t.pump();
    expect(find.text('Sync now'), findsOneWidget);
  });
}
