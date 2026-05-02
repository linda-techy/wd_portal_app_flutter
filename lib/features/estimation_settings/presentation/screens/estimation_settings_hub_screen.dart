import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EstimationSettingsHubScreen extends StatelessWidget {
  const EstimationSettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estimation Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Estimation Packages'),
              subtitle: const Text('Manage Basic / Standard / Premium tiers and their marketing names'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/estimation/packages'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.price_change_outlined),
              title: const Text('Package Rate Card'),
              subtitle: const Text('Manage per-package per-project-type rate version history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/estimation/rate-card'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up_outlined),
              title: const Text('Market Index'),
              subtitle: const Text('Publish commodity-rate snapshots; composite index computed server-side'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/estimation/market-index'),
            ),
          ),
        ],
      ),
    );
  }
}
