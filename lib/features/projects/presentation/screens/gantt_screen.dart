import 'package:flutter/material.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';
import 'package:admin/features/scheduling/data/services/monsoon_warning_service.dart';
import 'package:admin/features/scheduling/presentation/widgets/monsoon_warning_chip.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _GanttTask {
  final int id;
  final String title;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progressPercent;
  final bool overdue;

  const _GanttTask({
    required this.id,
    required this.title,
    required this.status,
    this.startDate,
    this.endDate,
    required this.progressPercent,
    required this.overdue,
  });

  factory _GanttTask.fromJson(Map<String, dynamic> json) {
    return _GanttTask(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'PENDING',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      overdue: json['overdue'] as bool? ?? false,
    );
  }
}

class _GanttData {
  final List<_GanttTask> tasks;
  final DateTime? projectStartDate;
  final DateTime? projectEndDate;
  final int overallProgress;
  final int overdueTasks;

  const _GanttData({
    required this.tasks,
    this.projectStartDate,
    this.projectEndDate,
    required this.overallProgress,
    required this.overdueTasks,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class GanttScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const GanttScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends State<GanttScreen> {
  final ApiService _api = ApiService();
  final MonsoonWarningService _monsoon = MonsoonWarningService();
  final ScrollController _hScroll = ScrollController();

  bool _isLoading = true;
  String? _error;
  _GanttData? _data;
  // taskId -> warning, populated after a successful Gantt load. Empty on
  // permission failure (the chip is non-blocking).
  Map<int, MonsoonWarning> _warningsByTask = const {};

  // px per day for bar sizing
  static const double _dayWidth = 24.0;
  static const double _rowHeight = 52.0;
  static const double _labelWidth = 200.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await _api.get('/api/projects/${widget.projectId}/schedule/gantt');
      final raw = resp.data is Map ? resp.data as Map<String, dynamic>
                                   : (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;

      final tasks = (payload['tasks'] as List? ?? [])
          .map((e) => _GanttTask.fromJson(e as Map<String, dynamic>))
          .toList();

      // Best-effort: also fetch monsoon warnings. Failure (e.g. 403 if the
      // user lacks MONSOON_WARNING_VIEW) must not block the Gantt.
      Map<int, MonsoonWarning> warnings = const {};
      try {
        final list = await _monsoon.warningsFor(widget.projectId);
        warnings = {for (final w in list) w.taskId: w};
      } catch (_) {
        // Silent: chips just won't render.
      }

      setState(() {
        _data = _GanttData(
          tasks: tasks,
          projectStartDate: payload['projectStartDate'] != null
              ? DateTime.tryParse(payload['projectStartDate'].toString())
              : null,
          projectEndDate: payload['projectEndDate'] != null
              ? DateTime.tryParse(payload['projectEndDate'].toString())
              : null,
          overallProgress: (payload['overallProgress'] as num?)?.toInt() ?? 0,
          overdueTasks: (payload['overdueTasks'] as num?)?.toInt() ?? 0,
        );
        _warningsByTask = warnings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _updateSchedule(
    _GanttTask task, {
    DateTime? startDate,
    DateTime? endDate,
    int? progressPercent,
  }) async {
    try {
      await _api.put(
        '/api/projects/${widget.projectId}/tasks/${task.id}/schedule',
        data: {
          if (startDate != null) 'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'endDate': endDate.toIso8601String().split('T')[0],
          if (progressPercent != null) 'progressPercent': progressPercent,
        },
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Bar colour by status ─────────────────────────────────────────────────

  Color _barColor(_GanttTask t) {
    if (t.overdue) return Colors.red.shade400;
    switch (t.status) {
      case 'COMPLETED': return Colors.green.shade500;
      case 'IN_PROGRESS': return Colors.blue.shade500;
      case 'CANCELLED': return Colors.grey.shade400;
      default: return Colors.blueGrey.shade300;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} — Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    final today = DateTime.now();

    // Determine chart date range
    DateTime chartStart = data.projectStartDate ?? today.subtract(const Duration(days: 7));
    DateTime chartEnd = data.projectEndDate ?? today.add(const Duration(days: 30));
    // Add 3-day padding on each side
    chartStart = chartStart.subtract(const Duration(days: 3));
    chartEnd = chartEnd.add(const Duration(days: 3));
    final totalDays = chartEnd.difference(chartStart).inDays;
    final chartWidth = totalDays * _dayWidth;

    // Today marker offset
    final todayOffset = today.difference(chartStart).inDays * _dayWidth;

    return Column(
      children: [
        _buildSummaryHeader(data),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed label column
              SizedBox(
                width: _labelWidth,
                child: Column(
                  children: [
                    // Header spacer matching the date ruler
                    Container(
                      height: 40,
                      color: Colors.grey.shade100,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 12),
                      child: const Text('Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.tasks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = data.tasks[i];
                          final warning = _warningsByTask[t.id];
                          return SizedBox(
                            height: _rowHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (warning != null) ...[
                                        const SizedBox(width: 4),
                                        MonsoonWarningChip(warning: warning),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _statusLabel(t),
                                    style: TextStyle(fontSize: 10, color: _barColor(t)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // Scrollable chart area
              Expanded(
                child: SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: Column(
                      children: [
                        // Date ruler
                        _buildDateRuler(chartStart, totalDays, chartWidth, todayOffset),
                        const Divider(height: 1),
                        // Chart rows
                        Expanded(
                          child: Stack(
                            children: [
                              // Rows
                              ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: data.tasks.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) => _buildChartRow(
                                    data.tasks[i], chartStart, chartWidth, todayOffset),
                              ),
                              // Today line (overlay)
                              if (todayOffset >= 0 && todayOffset <= chartWidth)
                                Positioned(
                                  left: todayOffset,
                                  top: 0,
                                  bottom: 0,
                                  child: _TodayLine(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(_GanttData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.deepSlate.withOpacity(0.05),
      child: Row(
        children: [
          _summaryChip(Icons.task_alt, '${data.tasks.length} tasks', Colors.blueGrey),
          const SizedBox(width: 12),
          _summaryChip(Icons.trending_up, '${data.overallProgress}% done', Colors.green),
          const SizedBox(width: 12),
          if (data.overdueTasks > 0)
            _summaryChip(Icons.warning_amber, '${data.overdueTasks} overdue', Colors.red),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDateRuler(DateTime chartStart, int totalDays, double chartWidth, double todayOffset) {
    // Show month labels
    final months = <DateTime, int>{};
    for (int d = 0; d < totalDays; d++) {
      final date = chartStart.add(Duration(days: d));
      final monthKey = DateTime(date.year, date.month);
      months.putIfAbsent(monthKey, () => d);
    }

    return Container(
      height: 40,
      color: Colors.grey.shade100,
      child: Stack(
        children: [
          for (final entry in months.entries)
            Positioned(
              left: entry.value * _dayWidth + 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  '${_monthName(entry.key.month)} ${entry.key.year}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            ),
          // Today label
          if (todayOffset >= 0 && todayOffset <= chartWidth)
            Positioned(
              left: todayOffset - 12,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Today', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartRow(_GanttTask task, DateTime chartStart, double chartWidth, double todayOffset) {
    final start = task.startDate;
    final end = task.endDate;

    Widget bar = const SizedBox.shrink();
    double? barLeft;
    double? barWidth;

    if (start != null && end != null) {
      barLeft = start.difference(chartStart).inDays * _dayWidth;
      barWidth = (end.difference(start).inDays + 1) * _dayWidth;
      if (barWidth < 4) barWidth = 4;

      bar = Positioned(
        left: barLeft.clamp(0, chartWidth),
        top: 10,
        child: GestureDetector(
          onTap: () => _showEditDialog(task),
          child: Container(
            width: barWidth,
            height: _rowHeight - 20,
            decoration: BoxDecoration(
              color: _barColor(task).withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: const Offset(0, 1))],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  widthFactor: (task.progressPercent / 100).clamp(0.0, 1.0),
                  child: Container(color: Colors.white.withOpacity(0.25)),
                ),
                // Label
                Center(
                  child: Text(
                    '${task.progressPercent}%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // No dates — show a small diamond at the due-date position or a "no dates" indicator
      bar = Positioned(
        left: 8,
        top: 18,
        child: GestureDetector(
          onTap: () => _showEditDialog(task),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Set dates', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          // Alternating row background
          Positioned.fill(child: Container(color: Colors.transparent)),
          bar,
        ],
      ),
    );
  }

  Future<void> _showEditDialog(_GanttTask task) async {
    DateTime? startDate = task.startDate;
    DateTime? endDate = task.endDate;
    int progress = task.progressPercent;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            title: Text(task.title, style: const TextStyle(fontSize: 15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: const Text('Start Date', style: TextStyle(fontSize: 13)),
                  subtitle: Text(startDate != null ? _fmtDate(startDate!) : 'Not set'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setS(() => startDate = d);
                  },
                ),
                // End date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop, color: Colors.red),
                  title: const Text('End Date', style: TextStyle(fontSize: 13)),
                  subtitle: Text(endDate != null ? _fmtDate(endDate!) : 'Not set'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setS(() => endDate = d);
                  },
                ),
                // Progress
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Progress:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('$progress%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$progress%',
                  onChanged: (v) => setS(() => progress = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _updateSchedule(task, startDate: startDate, endDate: endDate, progressPercent: progress);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(_GanttTask t) {
    if (t.overdue) return 'Overdue';
    switch (t.status) {
      case 'COMPLETED': return 'Completed';
      case 'IN_PROGRESS': return 'In Progress';
      case 'CANCELLED': return 'Cancelled';
      default: return 'Pending';
    }
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month];
  }
}

// ─── Today marker widget ──────────────────────────────────────────────────────

class _TodayLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(2, double.infinity),
        painter: _DashedLinePainter(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 1.5;

    const dashHeight = 6.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
