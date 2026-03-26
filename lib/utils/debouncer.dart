import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debounces repeated calls to [run] so the action fires only after
/// [delay] has elapsed since the last call.
///
/// Usage:
/// ```dart
/// final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
///
/// // In search field onChange:
/// _debouncer.run(() => _loadData(search: value));
///
/// // In dispose():
/// _debouncer.dispose();
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending timer without firing the action.
  void cancel() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
