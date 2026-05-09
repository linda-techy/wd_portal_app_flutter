import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/models/auth_models.dart';
import 'package:admin/providers/pending_sync_provider.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakePendingSync extends ChangeNotifier implements PendingSyncProvider {
  int _c = 0;
  @override
  int get pendingCount => _c;
  void setCount(int v) {
    _c = v;
    notifyListeners();
  }

  @override
  bool get isOnline => true;
  @override
  bool get isSyncing => false;
  @override
  List<OutboxEntry> get queued => const [];
  @override
  List<OutboxEntry> get issues => const [];
  @override
  Future<void> syncNow() async {}
  @override
  Future<void> retryPermanent(int id) async {}
  @override
  Future<void> discardPermanent(int id) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stub PortalAuthProvider that skips the real provider's async _autoInitialize
/// (which schedules a 5s timer that leaks past the widget tree teardown and
/// fires the `Timer is still pending` assertion in flutter_test).
class _StubAuth extends ChangeNotifier implements PortalAuthProvider {
  @override
  UserInfo? get currentUser => null;
  @override
  UserInfo? get user => null;
  @override
  List<String> get permissions => const [];
  @override
  bool get isLoading => false;
  @override
  bool get isAuthenticated => false;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap({
  required PermissionProvider perms,
  required _FakePendingSync sync,
  void Function(int)? onClick,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<PermissionProvider>.value(value: perms),
        ChangeNotifierProvider<PendingSyncProvider>.value(value: sync),
        // SideMenu's footer reads PortalAuthProvider; the stub above keeps
        // the test sync — the production provider runs an async init timer
        // we don't want to leak across pumpWidget tear-down.
        ChangeNotifierProvider<PortalAuthProvider>(create: (_) => _StubAuth()),
      ],
      child: Scaffold(
        body: SideMenu(
          onMenuItemClick: onClick ?? (_) {},
          selectedIndex: 0,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Pending Sync hidden when user lacks TASK_EDIT', (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_VIEW'], 'SITE_ENGINEER');
    await t.pumpWidget(_wrap(perms: perms, sync: _FakePendingSync()));

    // Expand the Projects group so its items render.
    await t.tap(find.text('PROJECTS'));
    await t.pump();

    expect(find.text('Pending Sync'), findsNothing);
  });

  testWidgets(
      'Pending Sync visible with TASK_EDIT (no badge when count=0)',
      (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_EDIT', 'TASK_VIEW'], 'SITE_ENGINEER');
    final sync = _FakePendingSync();
    await t.pumpWidget(_wrap(perms: perms, sync: sync));

    await t.tap(find.text('PROJECTS'));
    await t.pump();

    expect(find.text('Pending Sync'), findsOneWidget);
    // No badge when count is zero — the icon renders bare.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Pending Sync shows badge when count > 0', (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_EDIT', 'TASK_VIEW'], 'SITE_ENGINEER');
    final sync = _FakePendingSync()..setCount(3);
    await t.pumpWidget(_wrap(perms: perms, sync: sync));

    await t.tap(find.text('PROJECTS'));
    await t.pump();

    expect(find.text('Pending Sync'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Tapping Pending Sync emits its index to onMenuItemClick',
      (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_EDIT', 'TASK_VIEW'], 'SITE_ENGINEER');
    final sync = _FakePendingSync()..setCount(1);

    int? clickedIndex;
    await t.pumpWidget(_wrap(
      perms: perms,
      sync: sync,
      onClick: (i) => clickedIndex = i,
    ));

    await t.tap(find.text('PROJECTS'));
    await t.pump();
    await t.tap(find.text('Pending Sync'));
    await t.pump();

    expect(clickedIndex, isNotNull);
    expect(clickedIndex, isPositive);
  });
}
