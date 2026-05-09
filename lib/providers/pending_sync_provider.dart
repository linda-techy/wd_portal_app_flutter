import 'dart:async';
import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:flutter/foundation.dart';

class PendingSyncProvider extends ChangeNotifier {
  PendingSyncProvider({required OutboxService outbox, required SyncService sync})
      : _outbox = outbox,
        _sync = sync {
    _queuedSub = _outbox.watchPending().listen((rows) {
      _queued = rows;
      notifyListeners();
    });
    _issuesSub = _outbox.watchPermanentFailures().listen((rows) {
      _issues = rows;
      notifyListeners();
    });
  }

  final OutboxService _outbox;
  final SyncService _sync;

  StreamSubscription<List<OutboxEntry>>? _queuedSub;
  StreamSubscription<List<OutboxEntry>>? _issuesSub;

  List<OutboxEntry> _queued = const [];
  List<OutboxEntry> _issues = const [];
  bool _isSyncing = false;

  int get pendingCount => _queued.length;
  List<OutboxEntry> get queued => List.unmodifiable(_queued);
  List<OutboxEntry> get issues => List.unmodifiable(_issues);
  bool get isSyncing => _isSyncing;

  Future<void> syncNow() async {
    _isSyncing = true;
    notifyListeners();
    try {
      await _sync.triggerSyncNow();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> retryPermanent(int id) => _outbox.retryPermanentFailure(id);
  Future<void> discardPermanent(int id) => _outbox.discardPermanentFailure(id);

  @override
  void dispose() {
    _queuedSub?.cancel();
    _issuesSub?.cancel();
    super.dispose();
  }
}
