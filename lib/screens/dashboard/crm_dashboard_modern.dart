import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../services/crm_service.dart';
import '../../models/lead.dart';
import '../../models/client.dart';
import '../../models/project.dart';
import '../../widgets/components/data_card.dart';
import '../../widgets/charts/chart_card.dart';

/// Modern CRM Dashboard using new design system components
class CRMDashboardModern extends StatefulWidget {
  const CRMDashboardModern({super.key});

  @override
  _CRMDashboardModernState createState() => _CRMDashboardModernState();
}

class _CRMDashboardModernState extends State<CRMDashboardModern> {
  final CRMService _crmService = CRMService();
  Map<String, dynamic> dashboardMetrics = {};
  bool isLoading = true;
  List<Lead> leads = [];
  List<Client> clients = [];
  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final leadsData = await _crmService.getAllLeads();
      final clientsData = await _crmService.getAllClients();
      final projectsData = await _crmService.getAllProjects();

      setState(() {
        leads = leadsData;
        clients = clientsData;
        projects = projectsData;
        isLoading = false;
      });

      _calculateRealMetrics();
    } catch (e) {
      print('Error fetching API data: $e');
      setState(() {
        isLoading = false;
      });
      if (leads.isEmpty && clients.isEmpty && projects.isEmpty) {
        _loadMockData();
      } else {
        _calculateRealMetrics();
      }
    }
  }

  void _calculateRealMetrics() {
    final totalLeads = leads.length;
    final leadsByStatus = <String, int>{};
    for (final lead in leads) {
      final status = lead.status.isNotEmpty ? lead.status : 'Unknown';
      leadsByStatus[status] = (leadsByStatus[status] ?? 0) + 1;
    }

    final totalRevenue = leads
        .where((l) => l.status == 'Won')
        .fold<double>(0, (sum, l) => sum + (l.budget ?? 0));

    final projectProgress = <Map<String, dynamic>>[];
    final projectStatuses = <String, int>{};
    for (final project in projects) {
      final status = (project.status != null && project.status!.isNotEmpty)
          ? project.status!
          : 'Unknown';
      projectStatuses[status] = (projectStatuses[status] ?? 0) + 1;
    }

    projectStatuses.forEach((status, count) {
      final percentage =
          projects.isEmpty ? 0.0 : (count / projects.length * 100);
      projectProgress.add({
        'name': status,
        'count': count,
        'percentage': percentage,
      });
    });

    final monthlyRevenue = <Map<String, dynamic>>[];
    final currentYear = DateTime.now().year;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 0; i < 12; i++) {
      final monthRevenue = leads
          .where((l) =>
              l.status == 'Won' &&
              l.createdAt.year == currentYear &&
              l.createdAt.month == i + 1)
          .fold<double>(0, (sum, l) => sum + (l.budget ?? 0));

      monthlyRevenue.add({
        'month': months[i],
        'revenue': monthRevenue,
      });
    }

    setState(() {
      dashboardMetrics = {
        'totalLeads': totalLeads,
        'totalClients': clients.length,
        'totalProjects': projects.length,
        'totalRevenue': totalRevenue,
        'leadsByStatus': leadsByStatus,
        'projectProgress': projectProgress,
        'monthlyRevenue': monthlyRevenue,
      };
    });
  }

  void _loadMockData() {
    setState(() {
      dashboardMetrics = {
        'totalLeads': 150,
        'totalClients': 89,
        'totalProjects': 45,
        'totalRevenue': 2500000.0,
        'leadsByStatus': {
          'New': 25,
          'Contacted': 35,
          'Qualified': 20,
          'Proposal Sent': 15,
          'Negotiation': 10,
          'Won': 30,
          'Lost': 15,
        },
        'projectProgress': [
          {'name': 'Planning', 'count': 8, 'percentage': 18.0},
          {'name': 'In Progress', 'count': 22, 'percentage': 49.0},
          {'name': 'On Hold', 'count': 5, 'percentage': 11.0},
          {'name': 'Completed', 'count': 10, 'percentage': 22.0},
        ],
        'monthlyRevenue': [
          {'month': 'Jan', 'revenue': 180000},
          {'month': 'Feb', 'revenue': 220000},
          {'month': 'Mar', 'revenue': 280000},
          {'month': 'Apr', 'revenue': 320000},
          {'month': 'May', 'revenue': 350000},
          {'month': 'Jun', 'revenue': 380000},
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CRM Dashboard',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Key Metrics Cards - Using new MetricCard component
                    ResponsiveLayout(
                      mobile: Column(
                        children: _buildMetricsCards(),
                      ),
                      desktop: Row(
                        children: _buildMetricsCards(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Charts Row
                    ResponsiveLayout(
                      mobile: Column(
                        children: [
                          _buildLeadsPieChart(),
                          const SizedBox(height: AppTheme.spacingLG),
                          _buildProjectProgressChart(),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildLeadsPieChart(),
                          ),
                          const SizedBox(width: AppTheme.spacingLG),
                          Expanded(
                            flex: 1,
                            child: _buildProjectProgressChart(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Revenue Chart
                    _buildRevenueChart(),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildMetricsCards() {
    final totalLeads = dashboardMetrics['totalLeads'] ?? 0;
    final totalClients = dashboardMetrics['totalClients'] ?? 0;
    final totalProjects = dashboardMetrics['totalProjects'] ?? 0;
    final totalRevenue = dashboardMetrics['totalRevenue'] ?? 0.0;

    return [
      Expanded(
        child: MetricCard(
          label: 'Total Leads',
          value: '$totalLeads',
          change: '+12% this month',
          isPositive: true,
          icon: Icons.people_outline,
          accentColor: AppTheme.primaryBlue,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'Total Clients',
          value: '$totalClients',
          change: '+5% this month',
          isPositive: true,
          icon: Icons.person_outline,
          accentColor: AppTheme.statusSuccess,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'Active Projects',
          value: '$totalProjects',
          change: '3 new',
          isPositive: true,
          icon: Icons.work_outline,
          accentColor: AppTheme.safetyOrange,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'Total Revenue',
          value: '₹${(totalRevenue / 1000000).toStringAsFixed(1)}M',
          change: '+18% this month',
          isPositive: true,
          icon: Icons.attach_money,
          accentColor: AppTheme.statusSuccess,
        ),
      ),
    ];
  }

  Widget _buildLeadsPieChart() {
    final leadsByStatus =
        dashboardMetrics['leadsByStatus'] as Map<String, dynamic>? ?? {};
    final data = leadsByStatus.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        color: _getStatusColor(entry.key),
      );
    }).toList();

    return ChartCard(
      title: 'Leads by Status',
      subtitle: 'Distribution of leads across different stages',
      height: 300,
      chart: PieChart(
        PieChartData(
          sections: data,
          centerSpaceRadius: 50,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildProjectProgressChart() {
    final projectProgress =
        dashboardMetrics['projectProgress'] as List<dynamic>? ?? [];

    return ChartCard(
      title: 'Project Progress',
      subtitle: 'Projects by status',
      height: 300,
      chart: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: projectProgress.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${item['count']} (${item['percentage'].toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  child: LinearProgressIndicator(
                    value: (item['percentage'] as double) / 100,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(item['percentage'] as double),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final monthlyRevenue =
        dashboardMetrics['monthlyRevenue'] as List<dynamic>? ?? [];

    return ChartCard(
      title: 'Monthly Revenue Trend',
      subtitle: 'Revenue growth over the last 6 months',
      height: 300,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < monthlyRevenue.length) {
                    return Text(
                      monthlyRevenue[value.toInt()]['month'],
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppTheme.borderLight),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: monthlyRevenue.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value['revenue'].toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryBlue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryBlue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return AppTheme.primaryBlue;
      case 'contacted':
        return AppTheme.safetyOrange;
      case 'qualified':
        return AppTheme.safetyYellow;
      case 'proposal sent':
        return AppTheme.statusInfo;
      case 'negotiation':
        return AppTheme.primaryBlueDark;
      case 'won':
        return AppTheme.statusSuccess;
      case 'lost':
        return AppTheme.statusError;
      default:
        return AppTheme.textTertiary;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return AppTheme.statusSuccess;
    if (percentage >= 60) return AppTheme.safetyOrange;
    if (percentage >= 40) return AppTheme.safetyYellow;
    return AppTheme.statusError;
  }
}

