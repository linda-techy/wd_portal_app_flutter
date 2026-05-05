import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_phase_edit_dialog.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_task_edit_dialog.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';
import 'package:admin/providers/permission_provider.dart';

class WbsTemplateEditorScreen extends StatefulWidget {
  /// `null` when creating a new template (provider already has a draft from
  /// `startNewDraft`); otherwise the existing template id.
  final int? templateId;
  final WbsTemplateProvider? providerOverride;

  const WbsTemplateEditorScreen({
    super.key,
    this.templateId,
    this.providerOverride,
  });

  @override
  State<WbsTemplateEditorScreen> createState() =>
      _WbsTemplateEditorScreenState();
}

class _WbsTemplateEditorScreenState extends State<WbsTemplateEditorScreen> {
  late final WbsTemplateProvider _provider;
  int _selectedPhaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? WbsTemplateProvider();
    if (widget.providerOverride == null && widget.templateId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _provider.loadEditing(widget.templateId!));
    }
  }

  @override
  void dispose() {
    if (widget.providerOverride == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        context.watch<PermissionProvider>().canManageWbsTemplates;

    return ChangeNotifierProvider<WbsTemplateProvider>.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<WbsTemplateProvider>(
            builder: (_, p, __) => Text(
              p.editing?.name ?? 'WBS Template',
            ),
          ),
          actions: [
            if (canManage)
              Consumer<WbsTemplateProvider>(
                builder: (_, p, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_as),
                    label: const Text('Save as new version'),
                    onPressed:
                        p.editing == null || p.isLoading ? null : _onSave,
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<WbsTemplateProvider>(
          builder: (context, p, _) {
            if (p.isLoading && p.editing == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (p.editing == null) {
              return Center(
                child: Text(p.errorMessage ?? 'No template loaded.'),
              );
            }
            return Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _buildPhasePane(p.editing!, canManage),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _buildTaskPane(p.editing!, canManage),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhasePane(WbsTemplate template, bool canManage) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Phases',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add phase',
                  onPressed: () => _onAddPhase(template),
                ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: canManage,
            itemCount: template.phases.length,
            onReorder: canManage
                ? (oldIdx, newIdx) => _onReorder(template, oldIdx, newIdx)
                : (_, __) {},
            itemBuilder: (_, i) {
              final phase = template.phases[i];
              return ListTile(
                key: ValueKey('phase-${phase.id ?? i}'),
                selected: i == _selectedPhaseIndex,
                title: Text(phase.name),
                subtitle: Text('${phase.tasks.length} tasks'),
                onTap: () => setState(() => _selectedPhaseIndex = i),
                trailing: canManage
                    ? IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _onEditPhase(template, i),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskPane(WbsTemplate template, bool canManage) {
    if (template.phases.isEmpty) {
      return const Center(child: Text('Add a phase to start.'));
    }
    final idx = _selectedPhaseIndex.clamp(0, template.phases.length - 1);
    final phase = template.phases[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  phase.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add task'),
                  onPressed: () => _onAddTask(template, idx),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Seq')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Weight')),
                DataColumn(label: Text('Floor')),
                DataColumn(label: Text('Monsoon')),
                DataColumn(label: Text('Pmt')),
                DataColumn(label: Text('Preds')),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (var i = 0; i < phase.tasks.length; i++)
                  _taskRow(template, idx, i, phase.tasks[i], canManage),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _taskRow(WbsTemplate t, int phaseIdx, int taskIdx,
      WbsTemplateTask task, bool canManage) {
    return DataRow(cells: [
      DataCell(Text(task.sequence.toString())),
      DataCell(Text(task.name)),
      DataCell(Text('${task.durationDays} days')),
      DataCell(Text(task.weightFactor?.toString() ?? '(duration)')),
      DataCell(Text(task.floorLoop.label)),
      DataCell(Icon(
        task.monsoonSensitive ? Icons.umbrella : Icons.remove,
        size: 16,
      )),
      DataCell(Icon(
        task.isPaymentMilestone ? Icons.payments : Icons.remove,
        size: 16,
      )),
      DataCell(Text(task.predecessors.length.toString())),
      DataCell(canManage
          ? IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _onEditTask(t, phaseIdx, taskIdx),
            )
          : const SizedBox.shrink()),
    ]);
  }

  Future<void> _onAddPhase(WbsTemplate template) async {
    final phase = await WbsPhaseEditDialog.show(
      context,
      nextSequence: template.phases.length + 1,
    );
    if (phase == null) return;
    final next = template.copyWith(phases: [...template.phases, phase]);
    _provider.updateEditing(next);
    setState(() => _selectedPhaseIndex = next.phases.length - 1);
  }

  Future<void> _onEditPhase(WbsTemplate template, int idx) async {
    final phase = await WbsPhaseEditDialog.show(
      context,
      existing: template.phases[idx],
      nextSequence: template.phases[idx].sequence,
    );
    if (phase == null) return;
    final phases = [...template.phases]..[idx] = phase;
    _provider.updateEditing(template.copyWith(phases: phases));
  }

  void _onReorder(WbsTemplate template, int oldIdx, int newIdx) {
    final phases = [...template.phases];
    if (newIdx > oldIdx) newIdx -= 1;
    final moved = phases.removeAt(oldIdx);
    phases.insert(newIdx, moved);
    // Re-sequence after drag
    final reseq = <WbsTemplatePhase>[];
    for (var i = 0; i < phases.length; i++) {
      reseq.add(phases[i].copyWith(sequence: i + 1));
    }
    _provider.updateEditing(template.copyWith(phases: reseq));
  }

  Future<void> _onAddTask(WbsTemplate template, int phaseIdx) async {
    final phase = template.phases[phaseIdx];
    final task = await WbsTaskEditDialog.show(
      context,
      template: template,
      nextSequence: phase.tasks.length + 1,
    );
    if (task == null) return;
    final phases = [...template.phases];
    phases[phaseIdx] = phase.copyWith(tasks: [...phase.tasks, task]);
    _provider.updateEditing(template.copyWith(phases: phases));
  }

  Future<void> _onEditTask(
      WbsTemplate template, int phaseIdx, int taskIdx) async {
    final phase = template.phases[phaseIdx];
    final task = await WbsTaskEditDialog.show(
      context,
      template: template,
      existing: phase.tasks[taskIdx],
      nextSequence: phase.tasks[taskIdx].sequence,
    );
    if (task == null) return;
    final tasks = [...phase.tasks]..[taskIdx] = task;
    final phases = [...template.phases]
      ..[phaseIdx] = phase.copyWith(tasks: tasks);
    _provider.updateEditing(template.copyWith(phases: phases));
  }

  Future<void> _onSave() async {
    final ok = await _provider.saveEditing();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Saved as v${_provider.editing!.version}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.errorMessage ?? 'Save failed')),
      );
    }
  }
}
