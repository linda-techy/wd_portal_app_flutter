import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/models/market_index_snapshot.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/new_market_index_dialog.dart';
import 'package:admin/features/estimation_settings/providers/market_index_provider.dart';
import 'package:admin/providers/permission_provider.dart';

class MarketIndexScreen extends StatefulWidget {
  /// Optional injected provider — used by tests. Production callers omit it.
  final MarketIndexProvider? providerOverride;

  const MarketIndexScreen({super.key, this.providerOverride});

  @override
  State<MarketIndexScreen> createState() => _MarketIndexScreenState();
}

class _MarketIndexScreenState extends State<MarketIndexScreen> {
  late final MarketIndexProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? MarketIndexProvider();
    if (widget.providerOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _provider.load());
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MarketIndexProvider>.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Market Index'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _provider.load,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Consumer<PermissionProvider>(
                builder: (context, perms, _) {
                  final canPublish = perms.canPublishMarketIndex;
                  return Tooltip(
                    message: canPublish
                        ? 'Publish a new snapshot'
                        : 'You do not have permission to publish snapshots',
                    child: FilledButton.icon(
                      onPressed: canPublish ? _onPublish : null,
                      icon: const Icon(Icons.add),
                      label: const Text('New Snapshot'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Consumer<MarketIndexProvider>(
          builder: (context, p, _) {
            if (p.isLoading && p.snapshots.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (p.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(p.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: p.load, child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }
            if (p.snapshots.isEmpty) {
              return const Center(child: Text('No market index snapshots yet.'));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: p.snapshots.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _buildSnapshotTile(p.snapshots[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [Text('Showing ${p.snapshots.length} snapshot(s)')],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSnapshotTile(MarketIndexSnapshot s) {
    final date = s.snapshotDate.toIso8601String().substring(0, 10);
    final composite = s.compositeIndex.toStringAsFixed(4);
    final pctDelta = ((s.compositeIndex - 1.0) * 100);
    final compositeHint = s.compositeIndex == 1.0
        ? '(baseline)'
        : pctDelta > 0
            ? '(${pctDelta.toStringAsFixed(2)}% above baseline)'
            : '(${(-pctDelta).toStringAsFixed(2)}% below baseline)';
    final ratesLine =
        'steel ₹${s.steelRate}/kg · cement ₹${s.cementRate}/bag · '
        'sand ₹${s.sandRate}/m³';
    final ratesLine2 =
        'aggregate ₹${s.aggregateRate}/m³ · tiles ₹${s.tilesRate}/sqft · '
        'electrical ₹${s.electricalRate}/sqft';
    final ratesLine3 = 'paints ₹${s.paintsRate}/L';
    return ListTile(
      isThreeLine: true,
      leading: s.active
          ? const CircleAvatar(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: Icon(Icons.check, size: 18),
            )
          : const CircleAvatar(child: Icon(Icons.history, size: 18)),
      title: Text(date,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('composite $composite   $compositeHint',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(ratesLine, style: const TextStyle(fontSize: 12)),
          Text(ratesLine2, style: const TextStyle(fontSize: 12)),
          Text(ratesLine3, style: const TextStyle(fontSize: 12)),
        ],
      ),
      trailing: s.active
          ? const Chip(
              label: Text('ACTIVE'),
              backgroundColor: Color(0xFFE8F5E9),
              labelStyle: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
            )
          : null,
    );
  }

  Future<void> _onPublish() async {
    // Pass the current active snapshot as a template so the admin doesn't
    // re-enter 14 values when only one or two changed.
    final active = _provider.snapshots.where((s) => s.active).firstOrNull;
    final form = await NewMarketIndexDialog.show(context, template: active);
    if (form == null) return;
    final rates = (form['rates'] as Map).cast<String, double>();
    final weights = (form['weights'] as Map).cast<String, double>();
    final created = await _provider.publish(
      steelRate: rates['steel']!,
      cementRate: rates['cement']!,
      sandRate: rates['sand']!,
      aggregateRate: rates['aggregate']!,
      tilesRate: rates['tiles']!,
      electricalRate: rates['electrical']!,
      paintsRate: rates['paints']!,
      weights: weights,
      snapshotDate: form['snapshotDate'] as DateTime?,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Snapshot published — composite ${created.compositeIndex.toStringAsFixed(4)}',
        )),
      );
    }
  }
}
