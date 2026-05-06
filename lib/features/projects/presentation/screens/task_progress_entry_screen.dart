import 'package:flutter/material.dart';

import '../widgets/task_progress_bottom_sheet.dart';

/// Mobile-friendly screen for site engineers to update task progress.
/// Designed phone-first; existing Gantt screen stays for desktop scheduling.
///
/// This is a scaffolding implementation — task fetching and PATCH wiring
/// happen via the [onLoadTasks] and [onSaveProgress] callbacks so the
/// screen can be unit-tested without depending on the actual HTTP service.
class TaskProgressEntryScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Future<List<TaskRow>> Function(String projectId, String filter)
      onLoadTasks;
  final Future<void> Function(String taskId, int progress, String? note)
      onSaveProgress;

  // S3 PR2 — completion-gate hooks. Optional so legacy call sites (which
  // wired only progress-percent) continue to compile; the bottom sheet
  // hides the Mark-complete row when either is null.
  final Future<bool> Function(String taskId)? onCheckCompletionPhoto;
  final Future<String> Function(String taskId)? onMarkComplete;

  const TaskProgressEntryScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onLoadTasks,
    required this.onSaveProgress,
    this.onCheckCompletionPhoto,
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
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
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
              if (widget.onCheckCompletionPhoto != null &&
                  widget.onMarkComplete != null)
                _MarkCompleteRow(
                  taskId: task.id,
                  onCheckPhoto: widget.onCheckCompletionPhoto!,
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

/// S3 PR2 — bottom-sheet row that gates task completion on a geotagged
/// COMPLETION SiteReport. When a Mark-complete callback succeeds the row
/// flips to a result banner showing the new task status (PENDING PM
/// APPROVAL or COMPLETED) so the site engineer gets immediate feedback.
class _MarkCompleteRow extends StatefulWidget {
  const _MarkCompleteRow({
    required this.taskId,
    required this.onCheckPhoto,
    required this.onMarkComplete,
    required this.onAfterMark,
  });

  final String taskId;
  final Future<bool> Function(String taskId) onCheckPhoto;
  final Future<String> Function(String taskId) onMarkComplete;
  final VoidCallback onAfterMark;

  @override
  State<_MarkCompleteRow> createState() => _MarkCompleteRowState();
}

class _MarkCompleteRowState extends State<_MarkCompleteRow> {
  bool? _hasPhoto;       // null while loading
  String? _resultStatus; // populated post-mark

  @override
  void initState() {
    super.initState();
    _checkPhoto();
  }

  Future<void> _checkPhoto() async {
    final has = await widget.onCheckPhoto(widget.taskId);
    if (mounted) setState(() => _hasPhoto = has);
  }

  Future<void> _doMark() async {
    final status = await widget.onMarkComplete(widget.taskId);
    if (mounted) {
      setState(() => _resultStatus = status);
      widget.onAfterMark();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultStatus != null) {
      final label = _resultStatus == 'PENDING_PM_APPROVAL'
          ? 'Pending PM approval'
          : 'Completed';
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
    }

    final canMark = _hasPhoto == true;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              canMark
                  ? 'Geotagged COMPLETION photo on file.'
                  : 'Upload a geotagged COMPLETION photo to enable Mark complete.',
              style: TextStyle(
                color: canMark ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: canMark ? _doMark : null,
            child: const Text('Mark complete'),
          ),
        ],
      ),
    );
  }
}
