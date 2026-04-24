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

  const TaskProgressEntryScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onLoadTasks,
    required this.onSaveProgress,
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
        child: TaskProgressBottomSheet(
          taskTitle: task.title,
          milestoneName: task.milestoneName,
          initialProgress: task.progressPercent,
          onSave: (p, n) async {
            await widget.onSaveProgress(task.id, p, n);
            if (mounted) _refresh();
          },
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
