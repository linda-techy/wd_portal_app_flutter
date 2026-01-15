import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/project_tracking_provider.dart';
import '../../models/project_phase.dart';
import '../../models/delay_log.dart';
import '../../models/project_variation.dart';
import '../../models/budget_models.dart';

/// Main Project Tracking Dashboard Screen
class ProjectTrackingScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectTrackingScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectTrackingScreen> createState() => _ProjectTrackingScreenState();
}

class _ProjectTrackingScreenState extends State<ProjectTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectTrackingProvider>().loadAllData(widget.projectId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Tracking'),
            Text(
              widget.projectName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Phases'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Delays'),
            Tab(icon: Icon(Icons.change_circle), text: 'Variations'),
            Tab(icon: Icon(Icons.account_balance), text: 'Budget'),
          ],
        ),
      ),
      body: Consumer<ProjectTrackingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.phases.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPhasesTab(provider),
              _buildDelaysTab(provider),
              _buildVariationsTab(provider),
              _buildBudgetTab(provider),
            ],
          );
        },
      ),
    );
  }

  // ===== PHASES TAB =====
  Widget _buildPhasesTab(ProjectTrackingProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHealthSummaryCard(provider),
          const SizedBox(height: 16),
          _buildSectionHeader('Construction Phases', Icons.timeline),
          const SizedBox(height: 8),
          if (provider.phases.isEmpty)
            _buildEmptyState('No phases defined', Icons.timeline),
          ...provider.phases.map((phase) => _buildPhaseCard(phase, provider)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard(ProjectTrackingProvider provider) {
    final health = provider.healthSummary;
    if (health == null) return const SizedBox.shrink();

    Color statusColor;
    switch (health.overallStatus) {
      case 'ON_TRACK':
        statusColor = Colors.green;
        break;
      case 'MINOR_DELAYS':
        statusColor = Colors.orange;
        break;
      case 'AT_RISK':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    health.statusDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${health.completionPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: health.completionPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', health.totalPhases.toString(), Icons.list),
                _buildStatItem('Completed', health.completedPhases.toString(), Icons.check_circle, Colors.green),
                _buildStatItem('Delayed', health.delayedPhases.toString(), Icons.warning, Colors.red),
                _buildStatItem('Variations', health.approvedVariations.toString(), Icons.change_circle, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPhaseCard(ProjectPhase phase, ProjectTrackingProvider provider) {
    Color statusColor;
    IconData statusIcon;
    switch (phase.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'IN_PROGRESS':
        statusColor = phase.isDelayed ? Colors.red : Colors.blue;
        statusIcon = phase.isDelayed ? Icons.warning : Icons.play_circle;
        break;
      case 'DELAYED':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.phaseName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    phase.statusDisplay,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateRange('Planned', phase.plannedStart, phase.plannedEnd),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateRange('Actual', phase.actualStart, phase.actualEnd),
                ),
              ],
            ),
            if (phase.delayDays != null && phase.delayDays! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${phase.delayDays} days delayed',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildPhaseActions(phase, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRange(String label, DateTime? start, DateTime? end) {
    final dateFormat = DateFormat('dd MMM');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              start != null ? dateFormat.format(start) : '—',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text(' → '),
            Text(
              end != null ? dateFormat.format(end) : '—',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseActions(ProjectPhase phase, ProjectTrackingProvider provider) {
    if (phase.status == 'COMPLETED') {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (phase.status == 'NOT_STARTED')
          ElevatedButton.icon(
            onPressed: () => provider.updatePhaseStatus(phase.id!, 'IN_PROGRESS'),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        if (phase.status == 'IN_PROGRESS' || phase.status == 'DELAYED') ...[
          ElevatedButton.icon(
            onPressed: () => provider.updatePhaseStatus(phase.id!, 'COMPLETED'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  // ===== DELAYS TAB =====
  Widget _buildDelaysTab(ProjectTrackingProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Delay Logs', Icons.warning_amber),
          const SizedBox(height: 8),
          if (provider.delayLogs.isEmpty)
            _buildEmptyState('No delays logged', Icons.check_circle),
          ...provider.delayLogs.map((delay) => _buildDelayCard(delay)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDelayCard(DelayLog delay) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    delay.delayTypeDisplay,
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${delay.daysDelayed} days',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(delay.fromDate)} → ${delay.toDate != null ? dateFormat.format(delay.toDate!) : 'Ongoing'}',
                ),
              ],
            ),
            if (delay.reasonText != null && delay.reasonText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                delay.reasonText!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== VARIATIONS TAB =====
  Widget _buildVariationsTab(ProjectTrackingProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Change Orders / Variations', Icons.change_circle),
          const SizedBox(height: 8),
          if (provider.variations.isEmpty)
            _buildEmptyState('No variations recorded', Icons.change_circle),
          ...provider.variations.map((v) => _buildVariationCard(v, provider)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildVariationCard(ProjectVariation variation, ProjectTrackingProvider provider) {
    Color statusColor;
    switch (variation.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'PENDING_APPROVAL':
        statusColor = Colors.orange;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    variation.description,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    variation.statusDisplay,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  _currencyFormat.format(variation.estimatedAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (variation.notes != null && variation.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                variation.notes!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            _buildVariationActions(variation, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationActions(ProjectVariation variation, ProjectTrackingProvider provider) {
    return Row(
      children: [
        if (variation.canSubmit)
          ElevatedButton.icon(
            onPressed: () => provider.submitVariation(variation.id!),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        if (variation.canApprove) ...[
          ElevatedButton.icon(
            onPressed: () => provider.approveVariation(variation.id!, 1, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => provider.approveVariation(variation.id!, 1, false),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  // ===== BUDGET TAB =====
  Widget _buildBudgetTab(ProjectTrackingProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPLSummaryCard(provider),
          const SizedBox(height: 16),
          _buildBudgetSummaryCard(provider),
          const SizedBox(height: 16),
          _buildSectionHeader('BOQ vs Actuals', Icons.compare_arrows),
          const SizedBox(height: 8),
          if (provider.budgetSummary?.items.isEmpty ?? true)
            _buildEmptyState('No BOQ items found', Icons.list_alt),
          ...?provider.budgetSummary?.items.map((item) => _buildBoqItemCard(item)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPLSummaryCard(ProjectTrackingProvider provider) {
    final pl = provider.plSummary;
    if (pl == null) return const SizedBox.shrink();

    final isProfit = pl.isProfit;
    final mainColor = isProfit ? Colors.green : Colors.red;

    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [mainColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: mainColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Project ${isProfit ? 'Profit' : 'Loss'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _currencyFormat.format(pl.grossProfit.abs()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Margin: ${pl.profitMarginPercentage.toStringAsFixed(1)}%',
              style: TextStyle(color: mainColor, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFinanceItem('Revenue', pl.totalRevenue, Colors.green),
                _buildFinanceItem('Materials', pl.materialCost, Colors.orange),
                _buildFinanceItem('Labour', pl.labourCost, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildBudgetSummaryCard(ProjectTrackingProvider provider) {
    final budget = provider.budgetSummary;
    if (budget == null) return const SizedBox.shrink();

    Color statusColor;
    switch (budget.status) {
      case 'ON_TRACK':
        statusColor = Colors.green;
        break;
      case 'NEAR_LIMIT':
        statusColor = Colors.orange;
        break;
      case 'OVER_BUDGET':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet),
                const SizedBox(width: 8),
                const Text(
                  'Budget vs Actuals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    budget.statusDisplay,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (budget.consumedPercentage / 100).clamp(0, 1),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${budget.consumedPercentage.toStringAsFixed(1)}% consumed',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBudgetStat('Budget', budget.totalBudget, Colors.blue),
                _buildBudgetStat('Actual', budget.totalActual, Colors.orange),
                _buildBudgetStat(
                  'Variance',
                  budget.variance,
                  budget.variance >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(value),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildBoqItemCard(BoqItemActual item) {
    Color statusColor;
    if (item.isOverBudget) {
      statusColor = Colors.red;
    } else if (item.isNearLimit) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBoqStat('Budget', item.budgetAmount),
                ),
                Expanded(
                  child: _buildBoqStat('Actual', item.actualAmount),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.consumedPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        item.unit ?? '',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoqStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(
          _currencyFormat.format(value),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ===== COMMON WIDGETS =====
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.coralRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

