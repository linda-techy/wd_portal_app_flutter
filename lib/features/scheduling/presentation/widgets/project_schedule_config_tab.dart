import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/models/project_schedule_config_model.dart';
import 'package:admin/features/scheduling/providers/project_schedule_config_provider.dart';
import 'package:admin/providers/permission_provider.dart';

/// Embedded section for the project detail screen — exposes the
/// project_schedule_config row + holiday overrides.
class ProjectScheduleConfigTab extends StatefulWidget {
  final int projectId;
  final ProjectScheduleConfigProvider? providerOverride;

  const ProjectScheduleConfigTab({
    super.key,
    required this.projectId,
    this.providerOverride,
  });

  @override
  State<ProjectScheduleConfigTab> createState() =>
      _ProjectScheduleConfigTabState();
}

class _ProjectScheduleConfigTabState extends State<ProjectScheduleConfigTab> {
  late final ProjectScheduleConfigProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ??
        ProjectScheduleConfigProvider(projectId: widget.projectId);
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
    final canEdit =
        context.watch<PermissionProvider>().canEditProjectScheduleConfig;
    final canOverride =
        context.watch<PermissionProvider>().canOverrideProjectHolidays;

    return ChangeNotifierProvider<ProjectScheduleConfigProvider>.value(
      value: _provider,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ProjectScheduleConfigProvider>(
            builder: (_, p, __) {
              if (p.isLoading && p.config == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (p.errorMessage != null && p.config == null) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(p.errorMessage!),
                );
              }
              if (p.config == null) {
                return const Text('No schedule config yet.');
              }
              return SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Schedule configuration',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Sunday is a working day'),
                    subtitle: const Text(
                        'When ON, Sundays are not skipped in working-day calculations.'),
                    value: p.config!.sundayWorking,
                    onChanged: canEdit
                        ? (v) => _save(p.config!.copyWith(sundayWorking: v))
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Monsoon start (MM-DD):')),
                      Text(_fmtMD(p.config!.monsoonStartMonth,
                          p.config!.monsoonStartDay)),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () =>
                              _editMonsoon(p.config!, isStart: true),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Monsoon end (MM-DD):')),
                      Text(_fmtMD(p.config!.monsoonEndMonth,
                          p.config!.monsoonEndDay)),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () =>
                              _editMonsoon(p.config!, isStart: false),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('District:')),
                      Text(p.config!.districtCode ?? '(none)'),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editDistrict(p.config!),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Project holiday overrides',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (canOverride)
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          onPressed: _onAddOverride,
                        ),
                    ],
                  ),
                  if (p.overrides.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child:
                          Text('(none)', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...p.overrides.map(
                      (o) {
                        final dateStr =
                            '${o.overrideDate.year.toString().padLeft(4, '0')}-'
                            '${o.overrideDate.month.toString().padLeft(2, '0')}-'
                            '${o.overrideDate.day.toString().padLeft(2, '0')}';
                        final ref = o.holidayId != null
                            ? 'Holiday #${o.holidayId}'
                            : (o.overrideName ?? 'Project-only');
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            o.action == HolidayOverrideAction.exclude
                                ? Icons.cancel
                                : Icons.add_circle,
                          ),
                          title: Text(o.action.label),
                          subtitle: Text('$dateStr  •  $ref'),
                          trailing: canOverride && o.id != null
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _provider.deleteOverride(o.id!),
                                )
                              : null,
                        );
                      },
                    ),
                ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _fmtMD(int m, int d) =>
      '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  Future<void> _editMonsoon(ProjectScheduleConfig cfg,
      {required bool isStart}) async {
    final initial = DateTime(
      2026,
      isStart ? cfg.monsoonStartMonth : cfg.monsoonEndMonth,
      isStart ? cfg.monsoonStartDay : cfg.monsoonEndDay,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      helpText: isStart
          ? 'Monsoon start (year ignored)'
          : 'Monsoon end (year ignored)',
    );
    if (picked == null) return;
    final next = isStart
        ? cfg.copyWith(
            monsoonStartMonth: picked.month, monsoonStartDay: picked.day)
        : cfg.copyWith(
            monsoonEndMonth: picked.month, monsoonEndDay: picked.day);
    await _save(next);
  }

  Future<void> _editDistrict(ProjectScheduleConfig cfg) async {
    final controller = TextEditingController(text: cfg.districtCode ?? '');
    final picked = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('District code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., KL-EKM'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await _save(picked.isEmpty
        ? cfg.copyWith(clearDistrictCode: true)
        : cfg.copyWith(districtCode: picked));
  }

  Future<void> _save(ProjectScheduleConfig next) async {
    final ok = await _provider.save(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(ok ? 'Saved.' : (_provider.errorMessage ?? 'Failed'))),
    );
  }

  Future<void> _onAddOverride() async {
    // Backend `HolidayOverrideRequest` requires `action` + `overrideDate`.
    // `holidayId` is optional (null for project-only ADD). `overrideName`
    // is also optional and only meaningful for project-only ADDs.
    final idController = TextEditingController();
    final nameController = TextEditingController();
    HolidayOverrideAction action = HolidayOverrideAction.exclude;
    DateTime? selectedDate;

    final picked = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add holiday override'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<HolidayOverrideAction>(
                  isExpanded: true,
                  value: action,
                  items: HolidayOverrideAction.values
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text(a.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => action = v);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate == null
                      ? 'Pick override date'
                      : 'Date: '
                          '${selectedDate!.year.toString().padLeft(4, '0')}-'
                          '${selectedDate!.month.toString().padLeft(2, '0')}-'
                          '${selectedDate!.day.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final today = DateTime.now();
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate ?? today,
                      firstDate: DateTime(today.year - 1),
                      lastDate: DateTime(today.year + 5),
                    );
                    if (d != null) setLocal(() => selectedDate = d);
                  },
                ),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Holiday ID (optional)',
                    helperText:
                        'Reference an existing holiday row, or leave blank '
                        'for a project-only ADD.',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (action == HolidayOverrideAction.add)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional, project-only ADD)',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDate == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (picked != true || selectedDate == null) return;
    final holidayId = int.tryParse(idController.text.trim());
    final name = nameController.text.trim();
    final ok = await _provider.addOverride(
      action: action,
      overrideDate: selectedDate!,
      holidayId: holidayId,
      overrideName: name.isEmpty ? null : name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Override added.'
            : (_provider.errorMessage ?? 'Failed to add override.')),
      ),
    );
  }
}
