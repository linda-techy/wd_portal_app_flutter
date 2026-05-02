import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/estimation_settings/presentation/dialogs/new_rate_version_dialog.dart';
import 'package:admin/features/estimation_settings/providers/estimation_packages_provider.dart';
import 'package:admin/features/estimation_settings/providers/rate_versions_provider.dart';

class RateCardScreen extends StatefulWidget {
  const RateCardScreen({super.key});

  @override
  State<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends State<RateCardScreen> {
  late final EstimationPackagesProvider _packagesProvider;
  late final RateVersionsProvider _versionsProvider;

  @override
  void initState() {
    super.initState();
    _packagesProvider = EstimationPackagesProvider();
    _versionsProvider = RateVersionsProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _packagesProvider.load();
      // Default-select the first active package once they're loaded
      if (_packagesProvider.packages.isNotEmpty) {
        await _versionsProvider.select(packageId: _packagesProvider.packages.first.id);
      }
    });
  }

  @override
  void dispose() {
    _packagesProvider.dispose();
    _versionsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EstimationPackagesProvider>.value(value: _packagesProvider),
        ChangeNotifierProvider<RateVersionsProvider>.value(value: _versionsProvider),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Package Rate Card'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _versionsProvider.load,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSelectors(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer2<EstimationPackagesProvider, RateVersionsProvider>(
        builder: (context, packagesP, versionsP, _) {
          return Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: versionsP.packageId,
                  decoration: const InputDecoration(labelText: 'Package'),
                  items: packagesP.packages
                      .map((p) => DropdownMenuItem<String>(
                            value: p.id,
                            child: Text('${p.internalName} — ${p.marketingName}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) versionsP.select(packageId: v);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<ProjectType>(
                  value: versionsP.projectType,
                  decoration: const InputDecoration(labelText: 'Project Type'),
                  items: ProjectType.values
                      .map((pt) => DropdownMenuItem<ProjectType>(
                            value: pt,
                            child: Text(pt.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) versionsP.select(projectType: v);
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: versionsP.packageId == null ? null : () => _onCreate(),
                icon: const Icon(Icons.add),
                label: const Text('New Version'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return Consumer<RateVersionsProvider>(
      builder: (context, p, _) {
        if (p.packageId == null) {
          return const Center(child: Text('Select a package to view its rate history.'));
        }
        if (p.isLoading && p.versions.isEmpty) {
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
        if (p.versions.isEmpty) {
          return const Center(child: Text('No rate versions yet for this combination.'));
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: p.versions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _buildVersionTile(p.versions[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [Text('Showing ${p.versions.length} version(s)')],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile(PackageRateVersion v) {
    final from = v.effectiveFrom.toIso8601String().substring(0, 10);
    final to = v.effectiveTo == null
        ? 'present'
        : v.effectiveTo!.toIso8601String().substring(0, 10);
    return ListTile(
      leading: v.isActive
          ? const CircleAvatar(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: Icon(Icons.check, size: 18),
            )
          : const CircleAvatar(child: Icon(Icons.history, size: 18)),
      title: Text('$from → $to'),
      subtitle: Text(
        'Material ₹${v.materialRate} / Labour ₹${v.labourRate} / Overhead ₹${v.overheadRate}'
        '   =   ₹${v.totalRate}/sqft',
      ),
      trailing: v.isActive
          ? const Chip(
              label: Text('ACTIVE'),
              backgroundColor: Color(0xFFE8F5E9),
              labelStyle: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
            )
          : null,
    );
  }

  Future<void> _onCreate() async {
    final form = await NewRateVersionDialog.show(context);
    if (form == null) return;
    final created = await _versionsProvider.createNewVersion(
      materialRate: form['materialRate'] as double,
      labourRate: form['labourRate'] as double,
      overheadRate: form['overheadRate'] as double,
      effectiveFrom: form['effectiveFrom'] as DateTime?,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New rate version created (₹${created.totalRate}/sqft)')),
      );
    }
  }
}
