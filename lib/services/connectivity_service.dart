import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;
  static StreamSubscription? _subscription;

  static bool get isOnline => _isOnline;

  static Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  static void dispose() => _subscription?.cancel();
}
