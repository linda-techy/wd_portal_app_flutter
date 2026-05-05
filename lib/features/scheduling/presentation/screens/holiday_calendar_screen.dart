import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';
import 'package:admin/features/scheduling/presentation/dialogs/holiday_edit_dialog.dart';
import 'package:admin/features/scheduling/providers/holiday_calendar_provider.dart';
import 'package:admin/providers/permission_provider.dart';

class HolidayCalendarScreen extends StatefulWidget {
  final HolidayCalendarProvider? providerOverride;

  const HolidayCalendarScreen({super.key, this.providerOverride});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  late final HolidayCalendarProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? HolidayCalendarProvider();
    if (widget.providerOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _provider.load());
    }
  }

  @override
  void dispose() {
    if (widget.providerOverride == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<PermissionProvider>().canManageHolidays;

    return ChangeNotifierProvider<HolidayCalendarProvider>.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Holiday Calendar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _provider.load(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: Consumer<HolidayCalendarProvider>(
                builder: (context, p, _) {
                  if (p.isLoading && p.holidays.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (p.errorMessage != null) {
                    return Center(child: Text(p.errorMessage!));
                  }
                  if (p.holidays.isEmpty) {
                    return const Center(
                      child: Text('No holidays for this filter.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: p.holidays.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _buildHolidayTile(p.holidays[i], canManage),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: canManage
            ? FloatingActionButton(
                onPressed: _onCreate,
                tooltip: 'New holiday',
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Consumer<HolidayCalendarProvider>(
        builder: (_, p, __) => Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Year:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: p.year,
                  items: [2026, 2027, 2028]
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      p.setYear(v);
                      p.load();
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Scope:'),
                const SizedBox(width: 8),
                // Backend requires a scope (no "All" option). Default
                // NATIONAL; user picks STATE/DISTRICT/PROJECT explicitly.
                DropdownButton<HolidayScope>(
                  value: p.scope,
                  items: HolidayScope.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      p.setScope(v);
                      p.load();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayTile(Holiday h, bool canManage) {
    final fmt = DateFormat.yMMMMd();
    return ListTile(
      leading: CircleAvatar(child: Text(h.scope.label[0])),
      title: Text(h.name),
      subtitle: Text(
        '${fmt.format(h.date)}  •  ${h.scope.label}'
        '${h.scopeRef != null ? " (${h.scopeRef})" : ""}'
        '  •  ${h.recurrenceType.label}',
      ),
      trailing: canManage
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _onEdit(h),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _onDelete(h),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _onCreate() async {
    final created = await HolidayEditDialog.show(context);
    if (created == null) return;
    final ok = await _provider.create(created);
    _toast(ok ? 'Holiday added.' : (_provider.errorMessage ?? 'Failed.'));
  }

  Future<void> _onEdit(Holiday h) async {
    final updated = await HolidayEditDialog.show(context, existing: h);
    if (updated == null || h.id == null) return;
    final ok = await _provider.patch(h.id!, updated.toJson());
    _toast(ok ? 'Holiday updated.' : (_provider.errorMessage ?? 'Failed.'));
  }

  Future<void> _onDelete(Holiday h) async {
    if (h.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete holiday?'),
        content: Text('${h.name} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _provider.delete(h.id!);
    _toast(ok ? 'Deleted.' : (_provider.errorMessage ?? 'Failed.'));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
