import 'package:flutter/material.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Per-project payment-stage template editor.
///
/// Loads the current template via GET, lets the user edit stage names,
/// percentages (shown as percent, e.g. 15.0 for 0.15), and optional milestone
/// descriptions. Validates that the total equals 100 % (±0.01) before saving.
class StageTemplateEditorScreen extends StatefulWidget {
  final int projectId;

  const StageTemplateEditorScreen({super.key, required this.projectId});

  @override
  State<StageTemplateEditorScreen> createState() =>
      _StageTemplateEditorScreenState();
}

// ── Per-row edit state ────────────────────────────────────────────────────────

class _RowState {
  final TextEditingController name;
  final TextEditingController percent;
  final TextEditingController description;

  _RowState({
    required String name,
    required double percentageFraction,
    String? description,
  })  : name = TextEditingController(text: name),
        percent = TextEditingController(
          text: _fractionToText(percentageFraction),
        ),
        description = TextEditingController(text: description ?? '');

  factory _RowState.empty() => _RowState(
        name: '',
        percentageFraction: 0,
        description: null,
      );

  void dispose() {
    name.dispose();
    percent.dispose();
    description.dispose();
  }

  double get percentValue =>
      double.tryParse(percent.text.trim()) ?? 0.0;

  double get percentageFraction => percentValue / 100.0;

  static String _fractionToText(double fraction) {
    final pct = fraction * 100;
    if (pct == pct.roundToDouble()) return pct.toStringAsFixed(0);
    return pct.toStringAsFixed(2);
  }
}

// ── Screen state ─────────────────────────────────────────────────────────────

class _StageTemplateEditorScreenState
    extends State<StageTemplateEditorScreen> {
  late final BoqPaymentService _service;

  List<_RowState> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _service = BoqPaymentService();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await _service.getStageTemplate(widget.projectId);
      if (!mounted) return;
      setState(() {
        _rows = rows
            .map((r) => _RowState(
                  name: r.name,
                  percentageFraction: r.percentageFraction,
                  description: r.milestoneDescription,
                ))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  // ── Derived state ──────────────────────────────────────────────────────────

  double get _totalPercent =>
      _rows.fold(0.0, (sum, r) => sum + r.percentValue);

  bool get _totalValid => (_totalPercent - 100.0).abs() <= 0.01;

  String get _totalLabel {
    final t = _totalPercent;
    final display =
        t == t.roundToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(2);
    return 'Total: $display%';
  }

  // ── Row mutations ──────────────────────────────────────────────────────────

  void _addRow() {
    setState(() => _rows.add(_RowState.empty()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final tmp = _rows[index - 1];
      _rows[index - 1] = _rows[index];
      _rows[index] = tmp;
    });
  }

  void _moveDown(int index) {
    if (index >= _rows.length - 1) return;
    setState(() {
      final tmp = _rows[index + 1];
      _rows[index + 1] = _rows[index];
      _rows[index] = tmp;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_totalValid || _saving) return;

    setState(() => _saving = true);
    try {
      // Re-number 1..N before sending.
      final payload = List.generate(
        _rows.length,
        (i) => StageTemplateRow(
          stageNumber: i + 1,
          name: _rows[i].name.text.trim(),
          percentageFraction: _rows[i].percentageFraction,
          milestoneDescription: _rows[i].description.text.trim().isEmpty
              ? null
              : _rows[i].description.text.trim(),
        ),
      );
      await _service.setStageTemplate(widget.projectId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Stage template saved'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Save failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Stage Template'),
        actions: [
          if (_loading || _saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError()
              : _buildEditor(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // ── Running total banner ────────────────────────────────────────────
        _TotalBanner(label: _totalLabel, valid: _totalValid),

        // ── Stage rows ─────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _StageRowCard(
              index: i,
              total: _rows.length,
              row: _rows[i],
              onMoveUp: () => _moveUp(i),
              onMoveDown: () => _moveDown(i),
              onDelete: () => _removeRow(i),
              onChanged: () => setState(() {}),
            ),
          ),
        ),

        // ── Bottom toolbar ─────────────────────────────────────────────────
        _BottomToolbar(
          totalValid: _totalValid,
          totalLabel: _totalLabel,
          saving: _saving,
          onAdd: _addRow,
          onSave: _save,
        ),
      ],
    );
  }
}

// ── Total banner ──────────────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  final String label;
  final bool valid;

  const _TotalBanner({required this.label, required this.valid});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: valid
          ? Colors.green.withOpacity(0.12)
          : Colors.red.withOpacity(0.12),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: valid ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 8),
          Text(
            valid ? label : '$label — must equal 100%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valid ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-row card ──────────────────────────────────────────────────────────────

class _StageRowCard extends StatelessWidget {
  final int index;
  final int total;
  final _RowState row;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _StageRowCard({
    required this.index,
    required this.total,
    required this.row,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row header: stage number + reorder + delete ────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppTheme.deepSlate,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Move up',
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: index == 0 ? null : onMoveUp,
                  color: AppTheme.deepSlate,
                ),
                IconButton(
                  tooltip: 'Move down',
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: index == total - 1 ? null : onMoveDown,
                  color: AppTheme.deepSlate,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red[400],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Name + Percentage (side by side on wide screens) ──────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row.name,
                    decoration: const InputDecoration(
                      labelText: 'Stage name',
                      hintText: 'Stage name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.percent,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Percentage',
                      hintText: 'e.g. 10',
                      suffixText: '%',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Milestone description (optional) ──────────────────────────
            TextField(
              controller: row.description,
              decoration: const InputDecoration(
                labelText: 'Milestone description (optional)',
                hintText: 'e.g. Foundation complete, slab cast',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom toolbar ────────────────────────────────────────────────────────────

class _BottomToolbar extends StatelessWidget {
  final bool totalValid;
  final String totalLabel;
  final bool saving;
  final VoidCallback onAdd;
  final VoidCallback onSave;

  const _BottomToolbar({
    required this.totalValid,
    required this.totalLabel,
    required this.saving,
    required this.onAdd,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add stage'),
            ),
            const Spacer(),
            if (!totalValid)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'Total must be 100%',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500),
                ),
              ),
            ElevatedButton.icon(
              onPressed: totalValid && !saving ? onSave : null,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: const Text('Save template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepSlate,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
