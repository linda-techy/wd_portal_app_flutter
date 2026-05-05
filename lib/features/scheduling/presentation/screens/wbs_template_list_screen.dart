import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';
import 'package:admin/providers/permission_provider.dart';

class WbsTemplateListScreen extends StatefulWidget {
  /// Optional injected provider — used by tests.
  final WbsTemplateProvider? providerOverride;

  const WbsTemplateListScreen({super.key, this.providerOverride});

  @override
  State<WbsTemplateListScreen> createState() => _WbsTemplateListScreenState();
}

class _WbsTemplateListScreenState extends State<WbsTemplateListScreen> {
  late final WbsTemplateProvider _provider;
  WbsProjectType? _filter;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? WbsTemplateProvider();
    if (widget.providerOverride == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _provider.loadList());
    }
  }

  @override
  void dispose() {
    if (widget.providerOverride == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<PermissionProvider>();
    final canManage = perms.canManageWbsTemplates;

    return ChangeNotifierProvider<WbsTemplateProvider>.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WBS Templates'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _provider.loadList(projectType: _filter),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: Consumer<WbsTemplateProvider>(
                builder: (context, p, _) {
                  if (p.isLoading && p.templates.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (p.errorMessage != null) {
                    return _ErrorState(
                      message: p.errorMessage!,
                      onRetry: () {
                        p.loadList(projectType: _filter);
                      },
                    );
                  }
                  if (p.templates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                                'No templates yet for this project type.'),
                            if (canManage) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('New version'),
                                onPressed: _filter == null ? null : _onCreate,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return _buildGrid(p.templates, canManage);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: canManage && _filter != null
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('New version'),
                onPressed: _onCreate,
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == null,
            onSelected: (_) {
              setState(() => _filter = null);
              _provider.loadList();
            },
          ),
          ...WbsProjectType.values.map((t) => ChoiceChip(
                label: Text(t.label),
                selected: _filter == t,
                onSelected: (_) {
                  setState(() => _filter = t);
                  _provider.loadList(projectType: t);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildGrid(List<WbsTemplate> templates, bool canManage) {
    final fmt = DateFormat.yMMMd();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (_, i) {
        final t = templates[i];
        return Card(
          child: InkWell(
            onTap: t.id == null
                ? null
                : () => context.go('/scheduling/templates/${t.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text('v${t.version}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.projectType.label,
                      style: TextStyle(color: Colors.grey[600])),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        t.isActive ? Icons.check_circle : Icons.pause_circle,
                        size: 16,
                        color: t.isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(t.isActive ? 'Active' : 'Inactive'),
                      const Spacer(),
                      if (t.updatedAt != null)
                        Text(fmt.format(t.updatedAt!),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          onPressed: t.id == null
                              ? null
                              : () =>
                                  context.go('/scheduling/templates/${t.id}'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCreate() {
    if (_filter == null) return;
    _provider.startNewDraft(_filter!);
    context.go('/scheduling/templates/new');
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
