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
  @override
  int get pendingCount => 0;
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
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

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
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _wrap({
  required PermissionProvider perms,
  void Function(int)? onClick,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<PermissionProvider>.value(value: perms),
        ChangeNotifierProvider<PendingSyncProvider>.value(
          value: _FakePendingSync(),
        ),
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
  testWidgets('My Tasks hidden when user lacks TASK_EDIT', (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_VIEW'], 'SITE_ENGINEER');
    await t.pumpWidget(_wrap(perms: perms));

    await t.tap(find.text('PROJECTS'));
    await t.pump();

    expect(find.text('My Tasks'), findsNothing);
  });

  testWidgets('My Tasks visible with TASK_EDIT', (t) async {
    final perms = PermissionProvider()
      ..setPermissions(['TASK_EDIT', 'TASK_VIEW'], 'SITE_ENGINEER');
    await t.pumpWidget(_wrap(perms: perms));

    await t.tap(find.text('PROJECTS'));
    await t.pump();

    expect(find.text('My Tasks'), findsOneWidget);
  });

  testWidgets('Tapping My Tasks emits index 34 to onMenuItemClick',
      (t) async {
    await t.binding.setSurfaceSize(const Size(900, 1600));
    final perms = PermissionProvider()
      ..setPermissions(['TASK_EDIT', 'TASK_VIEW'], 'SITE_ENGINEER');
    int? clickedIndex;

    await t.pumpWidget(_wrap(
      perms: perms,
      onClick: (i) => clickedIndex = i,
    ));

    await t.tap(find.text('PROJECTS'));
    await t.pump();
    await t.ensureVisible(find.text('My Tasks'));
    await t.pump();
    await t.tap(find.text('My Tasks'), warnIfMissed: false);
    await t.pump();

    expect(clickedIndex, 34);
  });
}
