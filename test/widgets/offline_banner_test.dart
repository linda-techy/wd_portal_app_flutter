import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/providers/pending_sync_provider.dart';
import 'package:admin/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Lightweight stand-in for [PendingSyncProvider] used by the banner tests.
/// Avoids spinning up Drift + ConnectivityService just to drive a few flags.
class _FakeSyncProvider extends ChangeNotifier implements PendingSyncProvider {
  bool _online = true;
  int _count = 0;
  bool _syncing = false;
  int syncNowCalls = 0;

  @override
  bool get isOnline => _online;
  @override
  int get pendingCount => _count;
  @override
  bool get isSyncing => _syncing;

  void emit({bool? online, int? count, bool? syncing}) {
    if (online != null) _online = online;
    if (count != null) _count = count;
    if (syncing != null) _syncing = syncing;
    notifyListeners();
  }

  @override
  Future<void> syncNow() async {
    syncNowCalls++;
  }

  @override
  List<OutboxEntry> get issues => const [];
  @override
  List<OutboxEntry> get queued => const [];
  @override
  Future<void> retryPermanent(int id) async {}
  @override
  Future<void> discardPermanent(int id) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(_FakeSyncProvider p) => MaterialApp(
      home: ChangeNotifierProvider<PendingSyncProvider>.value(
        value: p,
        child: const Scaffold(body: Column(children: [OfflineBanner()])),
      ),
    );

void main() {
  testWidgets('online + 0 queue → banner is hidden', (t) async {
    final p = _FakeSyncProvider()..emit(online: true, count: 0);
    await t.pumpWidget(_wrap(p));
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(find.textContaining('queued'), findsNothing);
    expect(find.textContaining('waiting'), findsNothing);
  });

  testWidgets('offline + 0 queue → "Offline — 0 items queued"', (t) async {
    final p = _FakeSyncProvider()..emit(online: false, count: 0);
    await t.pumpWidget(_wrap(p));
    expect(find.text('Offline — 0 items queued'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('offline + 2 queue → "Offline — 2 items queued"', (t) async {
    final p = _FakeSyncProvider()..emit(online: false, count: 2);
    await t.pumpWidget(_wrap(p));
    expect(find.text('Offline — 2 items queued'), findsOneWidget);
    // No "Sync now" button while offline.
    expect(find.widgetWithText(TextButton, 'Sync now'), findsNothing);
  });

  testWidgets('online + 3 queue → "3 items waiting to sync" + Sync now',
      (t) async {
    final p = _FakeSyncProvider()..emit(online: true, count: 3);
    await t.pumpWidget(_wrap(p));
    expect(find.text('3 items waiting to sync'), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sync now'), findsOneWidget);
  });

  testWidgets('Sync now button calls syncNow on the provider', (t) async {
    final p = _FakeSyncProvider()..emit(online: true, count: 2);
    await t.pumpWidget(_wrap(p));
    await t.tap(find.widgetWithText(TextButton, 'Sync now'));
    await t.pump();
    expect(p.syncNowCalls, 1);
  });

  testWidgets('isSyncing → button disabled and labelled "Syncing…"',
      (t) async {
    final p = _FakeSyncProvider()..emit(online: true, count: 1, syncing: true);
    await t.pumpWidget(_wrap(p));
    expect(find.widgetWithText(TextButton, 'Syncing…'), findsOneWidget);
    final btn = t.widget<TextButton>(find.byType(TextButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('tapping the banner pushes /sync/pending', (t) async {
    final p = _FakeSyncProvider()..emit(online: false, count: 1);
    String? pushedRoute;
    await t.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<PendingSyncProvider>.value(
        value: p,
        child: const Scaffold(body: OfflineBanner()),
      ),
      onGenerateRoute: (s) {
        pushedRoute = s.name;
        return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('pending')));
      },
    ));
    await t.tap(find.byType(InkWell));
    await t.pumpAndSettle();
    expect(pushedRoute, '/sync/pending');
  });

  testWidgets('without provider → banner collapses gracefully', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: OfflineBanner()),
    ));
    await t.pump();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('reactive: count updates flip the visible label', (t) async {
    final p = _FakeSyncProvider()..emit(online: true, count: 0);
    await t.pumpWidget(_wrap(p));
    expect(find.byType(InkWell), findsNothing);

    p.emit(count: 2);
    await t.pump();
    expect(find.text('2 items waiting to sync'), findsOneWidget);

    p.emit(count: 0);
    await t.pump();
    expect(find.byType(InkWell), findsNothing);
  });
}
