import 'dart:async';
import 'package:admin/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal stub. Plugs into ConnectivityService via constructor injection.
class _FakeConnectivity implements ConnectivityProbe {
  _FakeConnectivity(this._initial);
  final List<ConnectivityResult> _initial;
  final _ctrl = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _initial;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _ctrl.stream;

  void emit(List<ConnectivityResult> r) => _ctrl.add(r);
  Future<void> close() => _ctrl.close();
}

void main() {
  test('isOnline returns true for wifi/mobile, false for none', () async {
    final wifi = ConnectivityService(probe: _FakeConnectivity([ConnectivityResult.wifi]));
    expect(await wifi.isOnline(), isTrue);

    final off = ConnectivityService(probe: _FakeConnectivity([ConnectivityResult.none]));
    expect(await off.isOnline(), isFalse);
  });

  test('watchOnline emits true on wifi event, false on none', () async {
    final probe = _FakeConnectivity([ConnectivityResult.none]);
    final svc = ConnectivityService(probe: probe);
    final events = <bool>[];
    final sub = svc.watchOnline().listen(events.add);
    await Future<void>.delayed(Duration.zero); // allow seed emission
    probe.emit([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    probe.emit([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);

    expect(events, [false, true, false]);
    await sub.cancel();
    await probe.close();
  });
}
