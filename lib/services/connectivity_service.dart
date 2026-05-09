import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Test seam — production binds to the real [Connectivity] plugin.
abstract class ConnectivityProbe {
  Future<List<ConnectivityResult>> checkConnectivity();
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class _PluginProbe implements ConnectivityProbe {
  final Connectivity _c = Connectivity();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() => _c.checkConnectivity();
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _c.onConnectivityChanged;
}

/// Instance-based connectivity wrapper. Replaces the previous static-only
/// helper. The boolean stream emits an immediate seed value plus one event
/// per underlying [Connectivity] change.
class ConnectivityService {
  ConnectivityService({ConnectivityProbe? probe}) : _probe = probe ?? _PluginProbe();

  final ConnectivityProbe _probe;

  Future<bool> isOnline() async {
    final r = await _probe.checkConnectivity();
    return _resultToBool(r);
  }

  Stream<bool> watchOnline() async* {
    yield await isOnline();
    yield* _probe.onConnectivityChanged.map(_resultToBool);
  }

  static bool _resultToBool(List<ConnectivityResult> r) =>
      !r.contains(ConnectivityResult.none) && r.isNotEmpty;
}
