import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pending_sync_provider.dart';

/// S5 PR2: banner driven by [PendingSyncProvider].
///
/// Visible when offline OR when there are queued items. Tapping the banner
/// navigates to the `/sync/pending` route. When online with a non-empty queue
/// the banner shows a "Sync now" affordance.
///
/// If [PendingSyncProvider] isn't yet registered in the tree (e.g. before the
/// outbox stack has bootstrapped on cold start), the banner collapses to an
/// empty box rather than throwing.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Tolerate missing provider so the banner doesn't crash the app shell on
    // platforms where the outbox stack isn't initialised (web / integration).
    final sync = _maybeWatch(context);
    if (sync == null) return const SizedBox.shrink();

    final online = sync.isOnline;
    final count = sync.pendingCount;

    if (online && count == 0) return const SizedBox.shrink();

    final label = online
        ? '$count items waiting to sync'
        : 'Offline — $count items queued';

    return Material(
      color: online ? Colors.amber.shade700 : Colors.orange.shade800,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/sync/pending'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: [
              Icon(online ? Icons.sync : Icons.wifi_off,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (online && count > 0)
                TextButton(
                  onPressed: sync.isSyncing ? null : sync.syncNow,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(sync.isSyncing ? 'Syncing…' : 'Sync now'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PendingSyncProvider? _maybeWatch(BuildContext context) {
    try {
      return context.watch<PendingSyncProvider>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
