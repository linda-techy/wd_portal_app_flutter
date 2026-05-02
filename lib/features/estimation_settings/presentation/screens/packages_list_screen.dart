import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/package_edit_dialog.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';

class PackagesListScreen extends StatefulWidget {
  /// Optional injected provider — used by tests. Production callers omit it.
  final EstimationPackagesProvider? providerOverride;

  const PackagesListScreen({super.key, this.providerOverride});

  @override
  State<PackagesListScreen> createState() => _PackagesListScreenState();
}

class _PackagesListScreenState extends State<PackagesListScreen> {
  late final EstimationPackagesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? EstimationPackagesProvider();
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
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estimation Packages'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New package',
              onPressed: _onCreate,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _provider.load(),
            ),
          ],
        ),
        body: Consumer<EstimationPackagesProvider>(
          builder: (context, p, _) {
            if (p.isLoading && p.packages.isEmpty) {
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
                      FilledButton(
                        onPressed: () => p.load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: p.packages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final pkg = p.packages[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('#${pkg.displayOrder}')),
                        title: Text('${pkg.internalName}  —  ${pkg.marketingName}'),
                        subtitle: pkg.description != null && pkg.description!.isNotEmpty
                            ? Text(pkg.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (action) {
                            if (action == 'edit') _onEdit(pkg);
                            if (action == 'delete') _onDelete(pkg);
                          },
                        ),
                        // PopupMenuButton intentionally stays enabled even when the tile is "disabled"
                        // (greyed out for inactive packages) — admins need to edit/reactivate them.
                        enabled: pkg.active,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text('Showing ${p.packages.length} packages'),
                      const Spacer(),
                      Switch(
                        value: p.showInactive,
                        onChanged: (v) => p.setShowInactive(v),
                      ),
                      const Text('Show inactive'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onCreate() async {
    final form = await PackageEditDialog.show(context);
    if (form == null) return;
    final created = await _provider.create(
      internalName: form['internalName'] as String,
      marketingName: form['marketingName'] as String,
      tagline: form['tagline'] as String?,
      description: form['description'] as String?,
      displayOrder: form['displayOrder'] as int,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package "${created.marketingName}" created')),
      );
    }
  }

  Future<void> _onEdit(EstimationPackage pkg) async {
    final form = await PackageEditDialog.show(context, existing: pkg);
    if (form == null) return;
    final updated = await _provider.update(
      pkg.id,
      marketingName: form['marketingName'] as String,
      tagline: form['tagline'] as String?,
      description: form['description'] as String?,
      displayOrder: form['displayOrder'] as int,
      active: form['active'] as bool,
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package "${updated.marketingName}" updated')),
      );
    }
  }

  Future<void> _onDelete(EstimationPackage pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('Soft-delete "${pkg.marketingName}"? It will be hidden from the wizard but its rate-version history is preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _provider.delete(pkg.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package "${pkg.marketingName}" deleted')),
      );
    }
  }
}
