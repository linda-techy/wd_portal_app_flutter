import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/task_quality_gate.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/task_quality_gate_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Quality-gates panel for a task detail screen.
///
/// Shows 3 ITP gates (PRELIMINARY → IN_PROGRESS → FINAL) with status pills and
/// a sign-off action on the next-actionable gate. Sign-off requires the
/// `TASK_QC_SIGNOFF` permission.
class TaskQualityGatesPanel extends StatefulWidget {
  final int taskId;
  final VoidCallback? onChanged;

  const TaskQualityGatesPanel({
    super.key,
    required this.taskId,
    this.onChanged,
  });

  @override
  State<TaskQualityGatesPanel> createState() => _TaskQualityGatesPanelState();
}

class _TaskQualityGatesPanelState extends State<TaskQualityGatesPanel> {
  final _service = TaskQualityGateService();
  List<TaskQualityGate> _gates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gates = await _service.listGates(widget.taskId);
      if (!mounted) return;
      setState(() {
        _gates = gates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Returns the index of the next gate that's not yet cleared, or -1 if all
  /// are cleared. The user can sign off ONLY this gate; previous gates are
  /// frozen (server enforces this, but UI hides the affordance).
  int _nextActionableIndex() {
    for (var i = 0; i < _gates.length; i++) {
      if (!_gates[i].isCleared) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Failed to load quality gates: $_error',
                  style: const TextStyle(color: AppTheme.statusError)),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_gates.isEmpty) return const SizedBox.shrink();

    final canSignOff = context
        .watch<PermissionProvider>()
        .hasPermission('TASK_QC_SIGNOFF');
    final actionableIdx = _nextActionableIndex();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    size: 20, color: AppTheme.coralRed),
                const SizedBox(width: 8),
                const Text(
                  'Quality Gates (ITP)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '${_gates.where((g) => g.isCleared).length} / ${_gates.length} cleared',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sequential checks by the assigned site engineer. Final gate must PASS before this task can be marked COMPLETED.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _gates.length; i++)
              _buildGateRow(_gates[i], i == actionableIdx, canSignOff),
          ],
        ),
      ),
    );
  }

  Widget _buildGateRow(TaskQualityGate gate, bool isActionable, bool canSignOff) {
    final showAction = isActionable && canSignOff;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor(gate),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor(gate)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _badgeColor(gate),
                child: Text(
                  '${gate.orderIndex}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gate.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gate.description,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              _statusPill(gate),
            ],
          ),
          if (gate.isCleared || gate.isFailed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${gate.signedByName ?? 'Unknown'} · '
                    '${gate.signedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(gate.signedAt!.toLocal()) : '—'}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
            if (gate.notes != null && gate.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${gate.notes}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
            if (gate.isFailed &&
                gate.failureReason != null &&
                gate.failureReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Failure: ${gate.failureReason}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
          if (showAction) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _signOffDialog(gate, 'PASSED'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Pass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusSuccess,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _signOffDialog(gate, 'FAILED'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Fail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.statusError,
                    side: const BorderSide(color: AppTheme.statusError),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _signOffDialog(gate, 'NA'),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('N/A'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(TaskQualityGate gate) {
    final c = _badgeColor(gate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        gate.status,
        style: TextStyle(
            color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _badgeColor(TaskQualityGate gate) {
    if (gate.isPassed) return AppTheme.statusSuccess;
    if (gate.isNa)     return Colors.grey.shade600;
    if (gate.isFailed) return AppTheme.statusError;
    return AppTheme.safetyOrange;
  }

  Color _bgColor(TaskQualityGate gate) {
    if (gate.isPassed) return Colors.green.shade50;
    if (gate.isNa)     return Colors.grey.shade100;
    if (gate.isFailed) return Colors.red.shade50;
    return Colors.amber.shade50;
  }

  Color _borderColor(TaskQualityGate gate) {
    if (gate.isPassed) return Colors.green.shade200;
    if (gate.isNa)     return Colors.grey.shade300;
    if (gate.isFailed) return Colors.red.shade200;
    return Colors.amber.shade300;
  }

  Future<void> _signOffDialog(TaskQualityGate gate, String targetStatus) async {
    final notesController = TextEditingController(text: gate.notes ?? '');
    final reasonController = TextEditingController(text: gate.failureReason ?? '');
    final isFail = targetStatus == 'FAILED';
    final isNa = targetStatus == 'NA';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isFail
              ? 'Fail "${gate.displayName}"?'
              : isNa
                  ? 'Mark "${gate.displayName}" as N/A?'
                  : 'Pass "${gate.displayName}"?',
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gate.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              if (isFail) ...[
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Failure reason (required) *',
                    hintText:
                        'e.g. Rebar spacing exceeds spec by 15 mm at column C-3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isNa) ...[
                TextField(
                  controller: notesController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Justification (recommended)',
                    hintText:
                        'Why this check does not apply to this task',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (!isFail && !isNa) ...[
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFail
                  ? AppTheme.statusError
                  : (isNa ? Colors.grey.shade600 : AppTheme.statusSuccess),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (isFail && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('A failure reason is required.')));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(isFail ? 'Fail gate' : (isNa ? 'Mark N/A' : 'Pass gate')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.signOff(
        widget.taskId,
        gateType: gate.gateType,
        status: targetStatus,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        failureReason: isFail ? reasonController.text.trim() : null,
      );
      await _load();
      widget.onChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFail
                ? '${gate.displayName} marked FAILED'
                : isNa
                    ? '${gate.displayName} marked N/A'
                    : '${gate.displayName} passed',
          ),
          backgroundColor:
              isFail ? AppTheme.statusError : AppTheme.statusSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-off failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
