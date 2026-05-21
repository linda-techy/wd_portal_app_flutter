import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';
import 'package:admin/features/scheduling/data/services/monsoon_warning_service.dart';
import 'package:admin/features/scheduling/presentation/widgets/monsoon_warning_chip.dart';
import 'package:admin/features/scheduling/data/models/cpm_result_model.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_template_picker_flow.dart';
import 'package:admin/features/projects/providers/gantt_cpm_provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/screens/tasks/task_detail_screen.dart';
import 'package:admin/screens/tasks/widgets/predecessor_edit_dialog.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

/// Parses a gantt-payload date value into a UTC `DateTime`.
///
/// The schedule API ships `yyyy-MM-dd` strings — same shape as the CPM
/// payload. Routing through [parseUtcDate] (rather than `DateTime.tryParse`,
/// which returns local time) keeps `chartStart` in the same timezone domain
/// as `CpmTaskResult.efDate` / `lfDate`, so `Duration.inDays` math used for
/// float-bar geometry doesn't shift by `_dayWidth` on non-UTC hosts.
///
/// Falls back to `DateTime.tryParse` if the string isn't strict `yyyy-MM-dd`
/// (defensive — but the chart still mixes domains in that fallback path).
DateTime? _parseGanttPayloadDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  // Strict yyyy-MM-dd → UTC midnight. Anything else (e.g. ISO datetime with
  // a 'T') falls back to tryParse.
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    return parseUtcDate(s);
  }
  final parsed = DateTime.tryParse(s);
  return parsed?.toUtc();
}

class _GanttTask {
  final int id;
  final String title;
  final String status;
  /// Effective bar geometry — plan if set, else CPM-derived (es/ef).
  final DateTime? startDate;
  final DateTime? endDate;
  /// Plan dates as committed by the user. Null when the bar is purely
  /// CPM-derived → render the bar muted/dashed so it's obvious the schedule
  /// hasn't been pinned yet.
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final int progressPercent;
  final bool overdue;

  const _GanttTask({
    required this.id,
    required this.title,
    required this.status,
    this.startDate,
    this.endDate,
    this.plannedStartDate,
    this.plannedEndDate,
    required this.progressPercent,
    required this.overdue,
  });

  /// True when the bar is being displayed from CPM-derived dates rather than
  /// from a committed plan. Used by the chart to render muted/dashed bars.
  bool get isPlanCommitted =>
      plannedStartDate != null && plannedEndDate != null;

  factory _GanttTask.fromJson(Map<String, dynamic> json) {
    return _GanttTask(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'PENDING',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      plannedStartDate: json['plannedStartDate'] != null
          ? DateTime.tryParse(json['plannedStartDate'].toString())
          : null,
      plannedEndDate: json['plannedEndDate'] != null
          ? DateTime.tryParse(json['plannedEndDate'].toString())
          : null,
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
    // Kick off CPM load after the first frame so context.read is safe and
    // notifyListeners doesn't fire during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GanttCpmProvider>().load(widget.projectId);
    });
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
          // Parse via parseUtcDate (not DateTime.tryParse, which returns local
          // time) so chartStart mixes cleanly with UTC ef/lf dates from
          // CpmResultModel in float-bar geometry. Mixing local + UTC in
          // Duration.inDays math shifted bars by _dayWidth on non-UTC runners.
          projectStartDate: _parseGanttPayloadDate(payload['projectStartDate']),
          projectEndDate: _parseGanttPayloadDate(payload['projectEndDate']),
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
    final perms = context.watch<PermissionProvider>();
    final canApplyWbs = perms.hasPermission('PROJECT_WBS_CLONE');
    final canCreateTask = perms.hasPermission('TASK_CREATE');

    final hasNoTasks =
        !_isLoading && _error == null && (_data?.tasks.isEmpty ?? true);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} — Timeline'),
        actions: [
          if (canApplyWbs)
            IconButton(
              icon: const Icon(Icons.account_tree_outlined),
              onPressed: _applyWbsTemplate,
              tooltip: 'Apply WBS Template',
            ),
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
              : hasNoTasks
                  ? _buildEmptyState(canApplyWbs)
                  : _buildContent(),
      floatingActionButton: (canCreateTask && !_isLoading && _error == null)
          ? FloatingActionButton.extended(
              onPressed: _showCreateTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool canApplyWbs) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_timeline_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No schedule tasks yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              Text(
                canApplyWbs
                    ? 'Start by applying a WBS template — that materialises every '
                        'phase and task in one click. Or add a single task with the +.'
                    : 'A user with PROJECT_WBS_CLONE permission can apply a WBS '
                        'template to populate the schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (canApplyWbs)
                ElevatedButton.icon(
                  onPressed: _applyWbsTemplate,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Apply WBS Template'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fetch the project (for projectType + floors) then run the picker flow.
  /// Picker handles its own snackbars + 409 / error reporting.
  Future<void> _applyWbsTemplate() async {
    try {
      final resp = await _api.get('/customer-projects/${widget.projectId}');
      final raw = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final payload = raw.containsKey('data') && raw['data'] is Map
          ? raw['data'] as Map<String, dynamic>
          : raw;
      final project = CustomerProject.fromJson(payload);
      if (!mounted) return;
      final perms = context.read<PermissionProvider>();
      await runWbsTemplatePickerFlow(
          context: context, project: project, perms: perms);
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open template picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateTaskDialog(
        projectId: widget.projectId,
        existingTasks: _data?.tasks ?? const [],
      ),
    );
    if (created == true && mounted) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created.'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    return Consumer<GanttCpmProvider>(
      builder: (context, cpm, _) => _buildContentWithCpm(cpm.cpmByTaskId),
    );
  }

  Widget _buildContentWithCpm(Map<int, CpmTaskResult> cpm) {
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
                          final isCritical = cpm[t.id]?.isCritical == true;
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
                                      if (isCritical) ...[
                                        Icon(Icons.local_fire_department,
                                            size: 14, color: Colors.red.shade700),
                                        const SizedBox(width: 4),
                                      ],
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
                                    data.tasks[i], chartStart, chartWidth, todayOffset, cpm),
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
    // Count tasks whose bar comes from CPM (no committed plan yet).
    final autoCount = data.tasks.where((t) => !t.isPlanCommitted).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.deepSlate.withOpacity(0.05),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _summaryChip(Icons.task_alt, '${data.tasks.length} tasks', Colors.blueGrey),
          _summaryChip(Icons.trending_up, '${data.overallProgress}% done', Colors.green),
          if (data.overdueTasks > 0)
            _summaryChip(Icons.warning_amber, '${data.overdueTasks} overdue', Colors.red),
          if (autoCount > 0)
            _legendChip(
              dimmed: true,
              label: '$autoCount auto-scheduled',
              tooltip:
                  'Bars rendered from CPM-derived dates. Drag or edit a bar to commit the plan.',
            ),
        ],
      ),
    );
  }

  /// Inline legend chip mirroring the muted bar style so users can mentally
  /// connect dim bar = CPM auto-schedule.
  Widget _legendChip({
    required bool dimmed,
    required String label,
    required String tooltip,
  }) {
    final color = Colors.blueGrey.shade400;
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 10,
            decoration: BoxDecoration(
              color: color.withOpacity(dimmed ? 0.55 : 1.0),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withOpacity(0.7), width: 1.2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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

  Widget _buildChartRow(
    _GanttTask task,
    DateTime chartStart,
    double chartWidth,
    double todayOffset,
    Map<int, CpmTaskResult> cpm,
  ) {
    final start = task.startDate;
    final end = task.endDate;
    final cpmTask = cpm[task.id];
    final isCritical = cpmTask?.isCritical ?? false;

    Widget bar = const SizedBox.shrink();
    Widget? floatBar;

    if (start != null && end != null) {
      final barLeft = start.difference(chartStart).inDays * _dayWidth;
      var barWidth = (end.difference(start).inDays + 1) * _dayWidth;
      if (barWidth < 4) barWidth = 4;

      // Critical-path overrides the default bar styling.
      // When the bar is rendered from CPM-derived dates (plan not yet
      // committed), dim the fill + use a dashed outline + drop the shadow.
      // Mirrors the construction-PM convention of "soft" / "rolling" bars
      // for auto-scheduled work, vs solid bars for committed plan.
      final isPlanCommitted = task.isPlanCommitted;
      final baseFill =
          isCritical ? Colors.red.shade400 : _barColor(task);
      final fillColor = isPlanCommitted
          ? baseFill
          : baseFill.withOpacity(0.55);
      final borderColor = isPlanCommitted
          ? (isCritical ? Colors.red.shade700 : Colors.transparent)
          : (isCritical ? Colors.red.shade700 : baseFill.withOpacity(0.7));
      final borderWidth = isPlanCommitted
          ? (isCritical ? 1.5 : 0)
          : 1.2;

      Widget barContainer = Container(
        key: Key('gantt-bar-${task.id}'),
        width: barWidth,
        height: _rowHeight - 20,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(
            color: borderColor,
            width: borderWidth.toDouble(),
            // DashStyle isn't a Flutter BoxBorder property — for the dashed
            // hint we add a corner stripe via a stack overlay below.
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isPlanCommitted
              ? const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ]
              : const [],
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
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      // When CPM data is available, wrap the bar with a Tooltip showing
      // ES/EF/LS/LF and float days.
      if (cpmTask != null) {
        // Tooltip surfaces ES/EF/LS/LF + float, and now a plan-status line so
        // the user knows whether the bar reflects a committed plan or the
        // CPM auto-schedule.
        final planLine = isPlanCommitted
            ? 'Plan: committed by user'
            : 'Plan: auto (CPM-derived — drag to commit)';
        barContainer = Tooltip(
          key: Key('gantt-bar-tooltip-${task.id}'),
          message: '${_tooltipFor(cpmTask)}\n$planLine',
          child: barContainer,
        );
      }

      bar = Positioned(
        left: barLeft.clamp(0, chartWidth),
        top: 10,
        child: GestureDetector(
          onTap: () => _showEditDialog(task),
          child: barContainer,
        ),
      );

      // Amber float bar — shown only for non-critical tasks with float > 0.
      // Build only if at least partially within the chart: previously the
      // left edge was clamped, but the bar could still draw a 4px stub at
      // the right edge when ef extended past the visible window.
      if (cpmTask != null &&
          !isCritical &&
          cpmTask.totalFloatDays > 0) {
        final floatLeft =
            cpmTask.efDate.difference(chartStart).inDays * _dayWidth;
        final floatWidth =
            cpmTask.lfDate.difference(cpmTask.efDate).inDays * _dayWidth;
        if (floatLeft < chartWidth && floatWidth > 0) {
          final clampedLeft = floatLeft.clamp(0.0, chartWidth.toDouble());
          final maxWidth = chartWidth - clampedLeft;
          final renderedWidth =
              floatWidth.toDouble().clamp(0.0, maxWidth.toDouble());
          if (renderedWidth > 0) {
            floatBar = Positioned(
              left: clampedLeft,
              top: _rowHeight / 2 - 2,
              child: Container(
                key: Key('gantt-float-${task.id}'),
                width: renderedWidth,
                height: 4,
                color: Colors.amber.shade300,
              ),
            );
          }
        }
      }
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
          if (floatBar != null) floatBar,
        ],
      ),
    );
  }

  String _tooltipFor(CpmTaskResult c) =>
      'ES: ${_fmtDate(c.esDate)}\n'
      'EF: ${_fmtDate(c.efDate)}\n'
      'LS: ${_fmtDate(c.lsDate)}\n'
      'LF: ${_fmtDate(c.lfDate)}\n'
      'Float: ${c.totalFloatDays} day${c.totalFloatDays == 1 ? '' : 's'}';

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
              // Open the full task-detail screen for title / description /
              // priority / assignee / status / QC-gates / delete. The Gantt
              // dialog itself only covers schedule (dates + progress).
              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Edit details'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(taskId: task.id),
                    ),
                  );
                  if (!mounted) return;
                  // Refresh after the user returns — they may have changed
                  // title, status, deleted the task, etc.
                  await _load();
                },
              ),
              // Predecessors quick-edit. Gated on TASK_EDIT; opens the same
              // dialog used by task_detail_screen but inline so the user
              // doesn't lose the Gantt context.
              if (context.read<PermissionProvider>().hasPermission('TASK_EDIT'))
                TextButton.icon(
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Predecessors'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final changed = await PredecessorEditDialog.show(
                      context,
                      taskId: task.id,
                      projectId: widget.projectId,
                      taskTitle: task.title,
                    );
                    if (changed == true && mounted) await _load();
                  },
                ),
              // Delete button — gated on TASK_DELETE permission (granted to
              // ADMIN and PROJECT_MANAGER per V5 seed). Server still enforces
              // the canModifyTask check (admin OR the project's specific PM
              // OR task creator) so unauthorized users get a clean 403.
              if (context.read<PermissionProvider>().hasPermission('TASK_DELETE'))
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.coralRed),
                  label: const Text('Delete',
                      style: TextStyle(color: AppTheme.coralRed)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _confirmDeleteTask(task);
                  },
                ),
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

  Future<void> _confirmDeleteTask(_GanttTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'This will permanently remove "${task.title}" and all of its quality-gate '
          'audit rows from the schedule. This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delete('/api/tasks/${task.id}');
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Task deleted'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
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

// ─── Create Task dialog ─────────────────────────────────────────────────────
//
// Minimal in-Gantt task-create flow. After creation, the user can edit further
// (assignee, priority, description) via the standard /tasks list. Optional
// predecessor picker is populated from the project's existing tasks loaded in
// the parent Gantt — no extra round-trip.

class _CreateTaskDialog extends StatefulWidget {
  final int projectId;
  final List<_GanttTask> existingTasks;

  const _CreateTaskDialog({
    required this.projectId,
    required this.existingTasks,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _lagController = TextEditingController(text: '0');
  final ApiService _api = ApiService();

  DateTime? _startDate;
  DateTime? _endDate;
  int? _predecessorTaskId;
  bool _submitting = false;
  String? _submitError;

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _lagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Auto-bump end if it's now before start
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _submitError = 'Start and end dates are required.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _submitError = 'End date must be on or after start date.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      // 1. Create the task. dueDate defaults to endDate (NOT NULL on the entity).
      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'priority': 'MEDIUM',
        'dueDate': _endDate!.toIso8601String().split('T').first,
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate!.toIso8601String().split('T').first,
        'project': {'id': widget.projectId},
        'customerVisible': true,
      };
      final resp = await _api.post('/api/tasks', data: body);
      final raw = resp.data is Map
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};
      final created = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      final newTaskId = (created['id'] as num?)?.toInt();

      // 2. Optionally wire a predecessor.
      if (newTaskId != null && _predecessorTaskId != null) {
        final lag = int.tryParse(_lagController.text.trim()) ?? 0;
        await _api.put('/api/tasks/$newTaskId/predecessors', data: {
          'predecessors': [
            {'predecessorId': _predecessorTaskId, 'lagDays': lag},
          ],
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Failed to create task: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add task to schedule'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(true),
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          _startDate == null
                              ? 'Start date *'
                              : 'Start: ${_fmt(_startDate!)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(false),
                        icon: const Icon(Icons.event_available, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'End date *'
                              : 'End: ${_fmt(_endDate!)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_durationDays > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Duration: $_durationDays calendar day${_durationDays == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Predecessor (optional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _predecessorTaskId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Must follow…',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...widget.existingTasks.map(
                      (t) => DropdownMenuItem<int?>(
                        value: t.id,
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _predecessorTaskId = v),
                ),
                if (_predecessorTaskId != null) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lagController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Lag (working days)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      helperText: 'Days after predecessor finishes before this can start',
                    ),
                  ),
                ],
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _submitError!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade900),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
