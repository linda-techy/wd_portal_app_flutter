import 'package:flutter/material.dart';
import 'package:admin/models/task_predecessor_edge.dart';
import 'package:admin/services/task_predecessor_service.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Modal dialog that lets an admin / PM / scheduler edit the predecessor
/// dependencies of one task.
///
/// Replace-all semantics: the server's `PUT /api/tasks/{taskId}/predecessors`
/// replaces the entire edge set in one call after running cycle detection on
/// every proposed edge. CPM is recomputed server-side immediately after save.
class PredecessorEditDialog extends StatefulWidget {
  final int taskId;
  final int projectId;
  final String taskTitle;

  const PredecessorEditDialog({
    super.key,
    required this.taskId,
    required this.projectId,
    required this.taskTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int taskId,
    required int projectId,
    required String taskTitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => PredecessorEditDialog(
        taskId: taskId,
        projectId: projectId,
        taskTitle: taskTitle,
      ),
    );
  }

  @override
  State<PredecessorEditDialog> createState() => _PredecessorEditDialogState();
}

class _PredecessorEditDialogState extends State<PredecessorEditDialog> {
  final _service = TaskPredecessorService();
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  String? _submitError;
  bool _submitting = false;

  /// Working list. UI mutates this; PUT only fires when user clicks Save.
  final List<_EditingEntry> _entries = [];

  /// All candidate tasks in the project (self + transitive successors filtered).
  List<_TaskOption> _allTasks = const [];

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
      // Two separate awaits — Future.wait widens to List<Object> which loses
      // the concrete types we need for `.data` access on the Response.
      final existing = await _service.list(widget.taskId);
      final ganttResp =
          await _api.get('/api/projects/${widget.projectId}/schedule/gantt');
      final raw = ganttResp.data;
      final data = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>?)
          : null;
      final taskList = (data?['tasks'] as List? ?? const [])
          .map((t) => _TaskOption(
                id: (t['id'] as num).toInt(),
                title: (t['title'] as String?) ?? '(no title)',
              ))
          .where((t) => t.id != widget.taskId) // can't depend on self
          .toList();

      if (!mounted) return;
      setState(() {
        _allTasks = taskList;
        _entries
          ..clear()
          ..addAll(existing.map((e) => _EditingEntry(
                predecessorId: e.predecessorId,
                predecessorTitle: e.predecessorTitle,
                lagDaysController:
                    TextEditingController(text: e.lagDays.toString()),
              )));
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

  void _addPredecessorPicker() async {
    final pickedId = await showDialog<int>(
      context: context,
      builder: (ctx) => _PredecessorPicker(
        candidates: _allTasks.where((t) =>
            !_entries.any((e) => e.predecessorId == t.id)).toList(),
      ),
    );
    if (pickedId == null) return;
    final picked = _allTasks.firstWhere((t) => t.id == pickedId);
    setState(() {
      _entries.add(_EditingEntry(
        predecessorId: picked.id,
        predecessorTitle: picked.title,
        lagDaysController: TextEditingController(text: '0'),
      ));
    });
  }

  void _remove(int index) {
    setState(() {
      _entries[index].lagDaysController.dispose();
      _entries.removeAt(index);
    });
  }

  Future<void> _save() async {
    // Validate lag-days parse
    final entries = <PredecessorEntry>[];
    for (final e in _entries) {
      final lag = int.tryParse(e.lagDaysController.text.trim());
      if (lag == null) {
        setState(() => _submitError =
            'Lag for "${e.predecessorTitle}" must be an integer.');
        return;
      }
      if (lag < 0) {
        setState(() => _submitError =
            'Lag for "${e.predecessorTitle}" cannot be negative.');
        return;
      }
      entries.add(PredecessorEntry(predecessorId: e.predecessorId, lagDays: lag));
    }

    setState(() {
      _submitError = null;
      _submitting = true;
    });
    try {
      await _service.replace(widget.taskId, entries);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // Server returns plain-text body on 400 (cycle / validation). Show as-is.
      String msg = e.toString();
      if (msg.length > 240) msg = '${msg.substring(0, 240)}…';
      setState(() {
        _submitError = msg;
        _submitting = false;
      });
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.lagDaysController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Predecessors of "${widget.taskTitle}"'),
      content: SizedBox(
        width: 560,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting || _loading ? null : _save,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save, size: 16),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.statusError, size: 40),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks listed below must FINISH before this one can START '
          '(plus the lag days, in working days).',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No predecessors yet — this task can start at project start.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _buildRow(i),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add predecessor'),
          onPressed: _addPredecessorPicker,
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _submitError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(int i) {
    final e = _entries[i];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              e.predecessorTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: e.lagDaysController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(),
                labelText: 'Lag (d)',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.statusError,
            onPressed: () => _remove(i),
          ),
        ],
      ),
    );
  }
}

class _EditingEntry {
  final int predecessorId;
  final String predecessorTitle;
  final TextEditingController lagDaysController;

  _EditingEntry({
    required this.predecessorId,
    required this.predecessorTitle,
    required this.lagDaysController,
  });
}

class _TaskOption {
  final int id;
  final String title;
  _TaskOption({required this.id, required this.title});
}

/// Small searchable picker used by the "Add predecessor" button.
class _PredecessorPicker extends StatefulWidget {
  final List<_TaskOption> candidates;
  const _PredecessorPicker({required this.candidates});

  @override
  State<_PredecessorPicker> createState() => _PredecessorPickerState();
}

class _PredecessorPickerState extends State<_PredecessorPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.candidates
        : widget.candidates
            .where((t) => t.title.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return AlertDialog(
      title: const Text('Pick a predecessor task'),
      content: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching tasks'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(t.title),
                          subtitle: Text('Task #${t.id}',
                              style: const TextStyle(fontSize: 11)),
                          onTap: () => Navigator.of(context).pop(t.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
      ],
    );
  }
}
