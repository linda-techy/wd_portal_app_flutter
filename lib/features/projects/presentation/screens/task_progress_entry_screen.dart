import 'package:flutter/material.dart';

import '../../domain/mark_complete_outcome.dart';
import '../widgets/task_progress_bottom_sheet.dart';

/// Mobile-friendly screen for site engineers to update task progress.
/// Designed phone-first; existing Gantt screen stays for desktop scheduling.
///
/// S5.1 — `onMarkComplete` now does the geotagged-photo capture + dual outbox
/// enqueue inside the wrapper passed in via DI. The screen-level callback
/// receives the parsed (taskId, projectId) and returns a [MarkCompleteOutcome]
/// the bottom-sheet maps onto its 6-state UI.
class TaskProgressEntryScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Future<List<TaskRow>> Function(String projectId, String filter)
      onLoadTasks;
  final Future<void> Function(String taskId, int progress, String? note)
      onSaveProgress;

  /// S5.1 — see `MarkCompleteOutcome`. Pass null to hide the Mark-complete
  /// row entirely (legacy / test scaffolding paths).
  final Future<MarkCompleteOutcome> Function(int taskId, int? projectId)?
      onMarkComplete;

  const TaskProgressEntryScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onLoadTasks,
    required this.onSaveProgress,
    this.onMarkComplete,
  });

  @override
  State<TaskProgressEntryScreen> createState() =>
      _TaskProgressEntryScreenState();
}

class _TaskProgressEntryScreenState extends State<TaskProgressEntryScreen> {
  String _filter = 'All';
  Future<List<TaskRow>>? _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _tasksFuture = widget.onLoadTasks(widget.projectId, _filter);
    });
  }

  void _openSheet(TaskRow task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaskProgressBottomSheet(
                taskTitle: task.title,
                milestoneName: task.milestoneName,
                initialProgress: task.progressPercent,
                onSave: (p, n) async {
                  await widget.onSaveProgress(task.id, p, n);
                  if (mounted) _refresh();
                },
              ),
              if (widget.onMarkComplete != null)
                _MarkCompleteRow(
                  taskRowId: task.id,
                  resolvedProjectId: int.tryParse(widget.projectId),
                  onMarkComplete: widget.onMarkComplete!,
                  onAfterMark: () {
                    if (mounted) _refresh();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: Text(widget.projectName)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: ['All', 'Active', 'Pending', 'Completed']
                    .map((f) => FilterChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) {
                            setState(() => _filter = f);
                            _refresh();
                          },
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TaskRow>>(
                future: _tasksFuture,
                builder: (c, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final tasks = snap.data ?? [];
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tasks for this filter',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) {
                        final t = tasks[i];
                        return ListTile(
                          title: Text(t.title),
                          subtitle: t.milestoneName != null
                              ? Text(t.milestoneName!)
                              : null,
                          trailing: Text('${t.progressPercent}%'),
                          onTap: () => _openSheet(t),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class TaskRow {
  final String id;
  final String title;
  final String? milestoneName;
  final int progressPercent;

  const TaskRow({
    required this.id,
    required this.title,
    this.milestoneName,
    required this.progressPercent,
  });
}

// ─── Bottom-sheet Mark-complete row (S5.1 state machine) ───────────────────

enum _MarkCompleteState {
  idle,
  capturing,
  queued,
  errorCameraDenied,
  errorGpsUnavailable,
  errorOutboxFailure,
}

class _MarkCompleteRow extends StatefulWidget {
  const _MarkCompleteRow({
    required this.taskRowId,
    required this.resolvedProjectId,
    required this.onMarkComplete,
    required this.onAfterMark,
  });

  /// `TaskRow.id` is `String` (the screen's data model is unchanged in S5.1).
  /// The row parses it to `int` before invoking [onMarkComplete]; an
  /// unparseable id flips immediately to [_MarkCompleteState.errorOutboxFailure].
  final String taskRowId;
  final int? resolvedProjectId;
  final Future<MarkCompleteOutcome> Function(int taskId, int? projectId)
      onMarkComplete;
  final VoidCallback onAfterMark;

  @override
  State<_MarkCompleteRow> createState() => _MarkCompleteRowState();
}

class _MarkCompleteRowState extends State<_MarkCompleteRow> {
  _MarkCompleteState _state = _MarkCompleteState.idle;
  String? _errorDetail; // optional message from MarkCompleteFailed

  Future<void> _onPressed() async {
    setState(() => _state = _MarkCompleteState.capturing);

    final taskId = int.tryParse(widget.taskRowId);
    if (taskId == null) {
      setState(() {
        _state = _MarkCompleteState.errorOutboxFailure;
        _errorDetail = 'Invalid task id';
      });
      return;
    }

    late MarkCompleteOutcome outcome;
    try {
      outcome = await widget.onMarkComplete(taskId, widget.resolvedProjectId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _MarkCompleteState.errorOutboxFailure;
        _errorDetail = null;
      });
      return;
    }

    if (!mounted) return;
    switch (outcome) {
      case MarkCompleteQueued():
        setState(() => _state = _MarkCompleteState.queued);
        widget.onAfterMark();
      case MarkCompleteFailed(reason: final r, message: final m):
        setState(() {
          _errorDetail = m;
          switch (r) {
            case MarkCompleteError.cameraDenied:
              _state = _MarkCompleteState.errorCameraDenied;
            case MarkCompleteError.gpsUnavailable:
              _state = _MarkCompleteState.errorGpsUnavailable;
            case MarkCompleteError.outboxFailure:
              _state = _MarkCompleteState.errorOutboxFailure;
          }
        });
    }
  }

  void _retry() {
    setState(() {
      _state = _MarkCompleteState.idle;
      _errorDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _MarkCompleteState.idle:
        return Row(
          children: [
            const Expanded(
              child: Text(
                'Capture a geotagged photo to mark this task complete.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _onPressed,
              child: const Text('Mark complete'),
            ),
          ],
        );
      case _MarkCompleteState.capturing:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Capturing photo + location...'),
            ),
          ],
        );
      case _MarkCompleteState.queued:
        return const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Queued — syncs when online')),
          ],
        );
      case _MarkCompleteState.errorCameraDenied:
        return _errorRow(
            'Camera permission denied. Mark complete cancelled.');
      case _MarkCompleteState.errorGpsUnavailable:
        return _errorRow(
            _errorDetail ??
                'Location unavailable. Mark complete requires GPS.');
      case _MarkCompleteState.errorOutboxFailure:
        return _errorRow("Couldn't queue. Try again.");
    }
  }

  Widget _errorRow(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: _retry, child: const Text('Retry')),
      ],
    );
  }
}
