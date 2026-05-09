import 'dart:async';
import 'package:admin/services/connectivity_service.dart';
import 'package:admin/widgets/offline_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Test seam fake — drives ConnectivityService.watchOnline() deterministically.
class _FakeProbe implements ConnectivityProbe {
  _FakeProbe(this._initial);
  final List<ConnectivityResult> _initial;
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _initial;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;

  void emit(List<ConnectivityResult> r) => _ctrl.add(r);
  Future<void> close() => _ctrl.close();
}

Widget _wrap(ConnectivityService svc) => MaterialApp(
      home: Provider<ConnectivityService>.value(
        value: svc,
        child: const Scaffold(body: OfflineBanner()),
      ),
    );

void main() {
  testWidgets('online → banner is hidden (renders empty)', (t) async {
    final probe = _FakeProbe([ConnectivityResult.wifi]);
    final svc = ConnectivityService(probe: probe);

    await t.pumpWidget(_wrap(svc));
    // Allow the seed emission from watchOnline() to flow through StreamBuilder.
    await t.pump();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
    // The widget should collapse to a SizedBox.shrink() — no Container painted.
    expect(find.byType(Container), findsNothing);

    await probe.close();
  });

  testWidgets('offline → banner shows wifi_off icon and message', (t) async {
    final probe = _FakeProbe([ConnectivityResult.none]);
    final svc = ConnectivityService(probe: probe);

    await t.pumpWidget(_wrap(svc));
    await t.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    await probe.close();
  });

  testWidgets('online → offline transition is reflected reactively',
      (t) async {
    final probe = _FakeProbe([ConnectivityResult.wifi]);
    final svc = ConnectivityService(probe: probe);

    await t.pumpWidget(_wrap(svc));
    await t.pump();

    // Initially online: banner hidden.
    expect(find.text('No internet connection'), findsNothing);

    // Drop connectivity.
    probe.emit([ConnectivityResult.none]);
    await t.pump();
    await t.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    // Recover connectivity.
    probe.emit([ConnectivityResult.wifi]);
    await t.pump();
    await t.pump();

    expect(find.text('No internet connection'), findsNothing);

    await probe.close();
  });
}
