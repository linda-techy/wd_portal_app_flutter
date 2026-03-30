import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/services/dashboard_service.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/models/dashboard_models.dart';
import 'package:admin/widgets/charts/chart_card.dart';
import '../../widgets/animations/shimmer_loading.dart';

class CRMDashboardModern extends StatefulWidget {
  const CRMDashboardModern({super.key});

  @override
  State<CRMDashboardModern> createState() => _CRMDashboardModernState();
}

class _CRMDashboardModernState extends State<CRMDashboardModern> {
  late DashboardService _dashboardService;
  DashboardData _data = DashboardData.empty();
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      _dashboardService =
          DashboardService(Provider.of<ApiService>(context, listen: false));
      _serviceInitialized = true;
      _loadData();
      _refreshTimer =
          Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _dashboardService.loadAll();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildShimmer()
            : _errorMessage != null
                ? _buildError()
                : _buildDashboard(),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerLoading(
              width: double.infinity,
              height: 120,
              borderRadius: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.coralRed, size: 48),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.deepSlate)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final isMobile = ResponsiveUtils.isMobile(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildOverviewSection(isMobile),
          const SizedBox(height: 24),
          _buildProjectHealthSection(isMobile),
          const SizedBox(height: 24),
          _buildFinancialSection(isMobile),
          const SizedBox(height: 24),
          _buildLeadsSection(isMobile),
          const SizedBox(height: 24),
          _buildOperationsSection(isMobile),
          if (_data.projects.atRisk.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAtRiskSection(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  // ─── Section 1: Overview KPIs ─────────────────────────────────────────────

  Widget _buildOverviewSection(bool isMobile) {
    final o = _data.overview;
    final f = _data.finance;
    final l = _data.leads;
    final cards = [
      _KpiData(
        title: 'Active Projects',
        value: '${o.totalActiveProjects}',
        subtitle: '${o.overdueProjects} overdue',
        icon: Icons.construction,
        color: AppTheme.primaryBlue,
        statusColor: o.overdueProjects > 0 ? AppTheme.coralRed : Colors.green,
      ),
      _KpiData(
        title: 'Revenue Collected',
        value: _formatCurrency(f.revenueCollected),
        subtitle: '${f.grossMarginPct.toStringAsFixed(1)}% margin',
        icon: Icons.payments_outlined,
        color: Colors.green,
        statusColor:
            f.grossMarginPct >= 20 ? Colors.green : Colors.orange,
      ),
      _KpiData(
        title: 'Open Leads',
        value: '${o.openLeads}',
        subtitle: '${l.hotLeads} hot',
        icon: Icons.people_outline,
        color: Colors.purple,
        statusColor: l.hotLeads > 0 ? Colors.orange : Colors.green,
      ),
      _KpiData(
        title: 'Tasks Due Today',
        value: '${o.tasksDueToday}',
        subtitle: '${o.overdueTasks} overdue',
        icon: Icons.task_alt,
        color: Colors.orange,
        statusColor: o.overdueTasks > 5 ? AppTheme.coralRed : Colors.orange,
      ),
    ];

    return isMobile
        ? Column(
            children: cards
                .map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildKpiCard(d),
                    ))
                .toList(),
          )
        : GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards.map(_buildKpiCard).toList(),
          );
  }

  Widget _buildKpiCard(_KpiData d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: d.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, color: d.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.title,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(d.value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepSlate)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: d.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(d.subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 2: Project Health ────────────────────────────────────────────

  Widget _buildProjectHealthSection(bool isMobile) {
    final p = _data.projects;
    return ChartCard(
      title: 'Project Health',
      chart: isMobile
          ? Column(
              children: [
                _buildProjectPhaseBars(p),
                const SizedBox(height: 20),
                _buildProjectStats(p),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildProjectPhaseBars(p)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildProjectStats(p)),
              ],
            ),
    );
  }

  Widget _buildProjectPhaseBars(DashboardProjects p) {
    if (p.byPhase.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('No project phase data available',
            style: TextStyle(color: Colors.grey)),
      ));
    }
    final total = p.byPhase.values.fold(0, (a, b) => a + b);
    final phaseColors = {
      'PLANNING': Colors.blue,
      'DESIGN': Colors.purple,
      'CONSTRUCTION': Colors.orange,
      'COMPLETION': Colors.green,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projects by Phase',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.deepSlate)),
        const SizedBox(height: 12),
        ...p.byPhase.entries.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color =
              phaseColors[e.key] ?? AppTheme.primaryBlue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.deepSlate)),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProjectStats(DashboardProjects p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.deepSlate)),
        const SizedBox(height: 12),
        _statRow('Total Projects', '${p.totalProjects}'),
        _statRow('Active', '${p.activeProjects}'),
        _statRow('Completed', '${p.completedProjects}'),
        _statRow('On Hold', '${p.onHoldProjects}'),
        _statRow('Overdue', '${p.overdueProjects}',
            valueColor: p.overdueProjects > 0 ? AppTheme.coralRed : null),
        const Divider(height: 20),
        _statRow('Total Budget', _formatCurrency(p.totalBudget)),
        _statRow('Avg Budget', _formatCurrency(p.averageBudget)),
        _statRow('Total Sqft',
            NumberFormat('#,##0').format(p.totalSqfeet.toInt())),
      ],
    );
  }

  // ─── Section 3: Financial Trend ───────────────────────────────────────────

  Widget _buildFinancialSection(bool isMobile) {
    final f = _data.finance;
    return ChartCard(
      title: 'Financial Overview',
      chart: Column(
        children: [
          if (f.monthlyRevenue.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: _buildRevenueLineChart(f.monthlyRevenue),
            ),
            const SizedBox(height: 8),
            _buildChartLegend(),
            const SizedBox(height: 16),
          ],
          isMobile
              ? Column(children: [
                  _financeChip('Total Cost', _formatCurrency(f.totalCost),
                      AppTheme.coralRed),
                  const SizedBox(height: 8),
                  _financeChip('Gross Margin',
                      '${_formatCurrency(f.grossMargin)} (${f.grossMarginPct.toStringAsFixed(1)}%)',
                      Colors.green),
                  const SizedBox(height: 8),
                  _financeChip('Pending Payments',
                      _formatCurrency(f.revenueTarget - f.revenueCollected > 0
                          ? f.revenueTarget - f.revenueCollected
                          : 0),
                      Colors.orange),
                ])
              : Row(
                  children: [
                    Expanded(
                        child: _financeChip('Total Cost',
                            _formatCurrency(f.totalCost), AppTheme.coralRed)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _financeChip(
                            'Gross Margin',
                            '${_formatCurrency(f.grossMargin)} (${f.grossMarginPct.toStringAsFixed(1)}%)',
                            Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _financeChip(
                            'Pending Payments',
                            _formatCurrency(f.revenueTarget -
                                        f.revenueCollected >
                                    0
                                ? f.revenueTarget - f.revenueCollected
                                : 0),
                            Colors.orange)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildRevenueLineChart(List<MonthlyRevenue> months) {
    if (months.isEmpty) return const SizedBox.shrink();

    double maxY = months.fold(0.0, (max, m) {
      final top =
          m.collected > m.invoiced ? m.collected : m.invoiced;
      return top > max ? top : max;
    });
    if (maxY == 0) maxY = 1000;

    final collectedSpots = months.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.collected);
    }).toList();
    final invoicedSpots = months.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.invoiced);
    }).toList();

    final labels = months.map((m) {
      final parts = m.month.split('-');
      if (parts.length == 2) {
        return DateFormat('MMM').format(
            DateTime(int.parse(parts[0]), int.parse(parts[1])));
      }
      return m.month;
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (months.length / 6).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(labels[idx],
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.deepSlate));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: collectedSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.08),
            ),
          ),
          LineChartBarData(
            spots: invoicedSpots,
            isCurved: true,
            color: AppTheme.primaryBlue,
            barWidth: 2,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(Colors.green, 'Collected'),
        const SizedBox(width: 16),
        _legendDot(AppTheme.primaryBlue, 'Invoiced', dashed: true),
      ],
    );
  }

  Widget _legendDot(Color color, String label, {bool dashed = false}) {
    return Row(
      children: [
        Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.deepSlate)),
      ],
    );
  }

  Widget _financeChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ─── Section 4: Lead Pipeline ─────────────────────────────────────────────

  Widget _buildLeadsSection(bool isMobile) {
    final l = _data.leads;
    return ChartCard(
      title: 'Lead Pipeline',
      chart: isMobile
          ? Column(children: [
              _buildLeadStatusBars(l),
              const SizedBox(height: 20),
              _buildLeadStats(l),
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildLeadStatusBars(l)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildLeadStats(l)),
              ],
            ),
    );
  }

  Widget _buildLeadStatusBars(DashboardLeads l) {
    if (l.byStatus.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('No lead data available',
            style: TextStyle(color: Colors.grey)),
      ));
    }
    final total = l.totalLeads > 0 ? l.totalLeads : 1;
    final statusColors = {
      'new': Colors.blue,
      'contacted': Colors.teal,
      'qualified': Colors.purple,
      'proposal_sent': Colors.orange,
      'converted': Colors.green,
      'lost': Colors.red,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('By Status',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.deepSlate)),
        const SizedBox(height: 12),
        ...l.byStatus.entries.map((e) {
          final pct = e.value / total;
          final color =
              statusColors[e.key.toLowerCase()] ?? Colors.blueGrey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatLeadStatus(e.key),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.deepSlate)),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLeadStats(DashboardLeads l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.deepSlate)),
        const SizedBox(height: 12),
        _statRow('Conversion Rate',
            '${l.conversionRate.toStringAsFixed(1)}%',
            valueColor: l.conversionRate >= 20 ? Colors.green : null),
        _statRow('Pipeline Value', _formatCurrency(l.pipelineValue)),
        _statRow('Hot Leads', '${l.hotLeads}',
            valueColor: l.hotLeads > 0 ? Colors.orange : null),
        _statRow('New (30 days)', '${l.newLeads}'),
        _statRow('Total Leads', '${l.totalLeads}'),
      ],
    );
  }

  // ─── Section 5: Operations Pulse ──────────────────────────────────────────

  Widget _buildOperationsSection(bool isMobile) {
    final op = _data.operations;
    final tiles = [
      _OpTile(
          Icons.people,
          'Labour on Site',
          '${op.labourOnSiteToday}',
          'Today',
          AppTheme.primaryBlue),
      _OpTile(
          Icons.assignment,
          'Site Reports',
          '${op.siteReportsThisWeek}',
          'This week',
          Colors.teal),
      _OpTile(
          Icons.visibility_outlined,
          'Observations',
          '${op.openObservations}',
          'Open',
          Colors.purple),
      _OpTile(
          Icons.pending_actions,
          'Approvals',
          '${op.pendingApprovals}',
          'Pending',
          Colors.orange),
    ];

    return ChartCard(
      title: 'Operations Today',
      chart: isMobile
          ? GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: tiles.map(_buildOpTile).toList(),
            )
          : Row(
              children: tiles
                  .map((t) =>
                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildOpTile(t),
                      )))
                  .toList(),
            ),
    );
  }

  Widget _buildOpTile(_OpTile t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(t.icon, color: t.color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: t.color)),
              Text(t.label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600])),
              Text(t.sublabel,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section 6: At-Risk Projects ──────────────────────────────────────────

  Widget _buildAtRiskSection() {
    return ChartCard(
      title: 'At-Risk Projects',
      chart: Column(
        children: _data.projects.atRisk
            .map((item) => _buildAtRiskRow(item))
            .toList(),
      ),
    );
  }

  Widget _buildAtRiskRow(ProjectHealthItem item) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/projects/${item.projectId}');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(item.projectName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.deepSlate)),
            ),
            if (item.overdueTasks > 0)
              _badge('${item.overdueTasks} overdue', AppTheme.coralRed),
            if (item.activeDelays > 0) ...[
              const SizedBox(width: 6),
              _badge('${item.activeDelays} delay${item.activeDelays > 1 ? 's' : ''}',
                  Colors.orange),
            ],
            if (item.budgetUtilizationPct != null &&
                item.budgetUtilizationPct! > 90) ...[
              const SizedBox(width: 6),
              _badge('${item.budgetUtilizationPct!.toStringAsFixed(0)}% budget',
                  Colors.purple),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _statRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppTheme.deepSlate)),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(0)}K';
    }
    return '₹${NumberFormat('#,##0').format(value.toInt())}';
  }

  String _formatLeadStatus(String status) {
    return status
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color statusColor;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.statusColor,
  });
}

class _OpTile {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _OpTile(
      this.icon, this.label, this.value, this.sublabel, this.color);
}
