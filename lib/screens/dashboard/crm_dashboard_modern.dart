import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/widgets/components/data_card.dart';
import 'package:admin/widgets/charts/chart_card.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/shimmer_loading.dart';

/// Modern CRM Dashboard using new design system components
class CRMDashboardModern extends StatefulWidget {
  const CRMDashboardModern({super.key});

  @override
  State<CRMDashboardModern> createState() => _CRMDashboardModernState();
}

class _CRMDashboardModernState extends State<CRMDashboardModern> {
  final CRMService _crmService = CRMService();
  Map<String, dynamic> dashboardMetrics = {};
  bool _isPageLoading = true;
  List<Lead> leads = [];
  List<Customer> customers = [];
  List<CustomerProject> customerProjects = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isPageLoading = true;
      });

      final leadsData = await _crmService.getAllLeads();
      final customersData = await _crmService.getAllCustomers();
      final projectsData = await _crmService.getAllCustomerProjects();

      setState(() {
        leads = leadsData;
        customers = customersData;
        customerProjects = projectsData;
        _isPageLoading = false;
      });

      _calculateRealMetrics();

    } catch (e) {
      debugPrint('Error fetching API data: $e');
      setState(() {
        _isPageLoading = false;
      });
      _calculateRealMetrics();
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
    for (final project in customerProjects) {
      final status = (project.projectPhase != null && project.projectPhase!.isNotEmpty)
          ? project.projectPhase!
          : (project.state != null && project.state!.isNotEmpty)
              ? project.state!
              : 'Unknown';
      projectStatuses[status] = (projectStatuses[status] ?? 0) + 1;
    }

    projectStatuses.forEach((status, count) {
      final percentage =
          customerProjects.isEmpty ? 0.0 : (count / customerProjects.length * 100);
      projectProgress.add({
        'name': status,
        'count': count,
        'percentage': percentage,
      });
    });

    final monthlyRevenue = <Map<String, dynamic>>[];
    final currentYear = DateTime.now().year;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

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
        'totalClients': customers.length,
        'totalProjects': customerProjects.length,
        'totalRevenue': totalRevenue,
        'leadsByStatus': leadsByStatus,
        'projectProgress': projectProgress,
        'monthlyRevenue': monthlyRevenue,
      };
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: _isPageLoading
            ? _buildShimmerLoading()
            : SingleChildScrollView(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CRM Dashboard',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loadDashboardData,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                      desktop: Row(
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
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Key Metrics Cards - Using new MetricCard component
                    ResponsiveLayout(
                      mobile: Column(
                        children: _buildMetricsCardsMobile(),
                      ),
                      tablet: Column(
                        children: _buildMetricsCardsTablet(),
                      ),
                      desktop: Row(
                        children: _buildMetricsCardsDesktop(),
                      ),

                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Charts Row
                    ResponsiveLayout(
                      mobile: Column(
                        children: [
                          EntranceAnimation(
                            delay: const Duration(milliseconds: 400),
                            child: _buildLeadsPieChart(),
                          ),
                          const SizedBox(height: AppTheme.spacingLG),
                          EntranceAnimation(
                            delay: const Duration(milliseconds: 500),
                            child: _buildProjectProgressChart(),
                          ),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: EntranceAnimation(
                              delay: const Duration(milliseconds: 400),
                              child: _buildLeadsPieChart(),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingLG),
                          Expanded(
                            flex: 1,
                            child: EntranceAnimation(
                              delay: const Duration(milliseconds: 500),
                              child: _buildProjectProgressChart(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Revenue Chart
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 600),
                      child: _buildRevenueChart(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 250, height: 32),
          const SizedBox(height: AppTheme.spacingLG),
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : AppTheme.spacingMD),
                  child: const ShimmerLoading(width: double.infinity, height: 120),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          const Row(
            children: [
              Expanded(child: ShimmerLoading(width: double.infinity, height: 300)),
              SizedBox(width: AppTheme.spacingLG),
              Expanded(child: ShimmerLoading(width: double.infinity, height: 300)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          const ShimmerLoading(width: double.infinity, height: 300),
        ],
      ),
    );
  }

  List<Widget> _buildMetricsCardsMobile() {
    final totalLeads = dashboardMetrics['totalLeads'] ?? 0;
    final totalClients = dashboardMetrics['totalClients'] ?? 0;
    final totalProjects = dashboardMetrics['totalProjects'] ?? 0;
    final totalRevenue = dashboardMetrics['totalRevenue'] ?? 0.0;

    return [
      EntranceAnimation(
        delay: const Duration(milliseconds: 0),
        child: MetricCard(
          label: 'Total Leads',
          value: '$totalLeads',
          change: '+12% this month',
          isPositive: true,
          icon: Icons.people_outline,
          accentColor: AppTheme.primaryBlue,
        ),
      ),
      const SizedBox(height: AppTheme.spacingMD),
      EntranceAnimation(
        delay: const Duration(milliseconds: 100),
        child: MetricCard(
          label: 'Total Clients',
          value: '$totalClients',
          change: '+5% this month',
          isPositive: true,
          icon: Icons.person_outline,
          accentColor: AppTheme.statusSuccess,
        ),
      ),
      const SizedBox(height: AppTheme.spacingMD),
      EntranceAnimation(
        delay: const Duration(milliseconds: 200),
        child: MetricCard(
          label: 'Active Projects',
          value: '$totalProjects',
          change: '3 new',
          isPositive: true,
          icon: Icons.work_outline,
          accentColor: AppTheme.safetyOrange,
        ),
      ),
      const SizedBox(height: AppTheme.spacingMD),
      EntranceAnimation(
        delay: const Duration(milliseconds: 300),
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

  List<Widget> _buildMetricsCardsDesktop() {
    final totalLeads = dashboardMetrics['totalLeads'] ?? 0;
    final totalClients = dashboardMetrics['totalClients'] ?? 0;
    final totalProjects = dashboardMetrics['totalProjects'] ?? 0;
    final totalRevenue = dashboardMetrics['totalRevenue'] ?? 0.0;

    return [
      Expanded(
        child: EntranceAnimation(
          delay: const Duration(milliseconds: 0),
          child: MetricCard(
            label: 'Total Leads',
            value: '$totalLeads',
            change: '+12% this month',
            isPositive: true,
            icon: Icons.people_outline,
            accentColor: AppTheme.primaryBlue,
          ),
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: EntranceAnimation(
          delay: const Duration(milliseconds: 100),
          child: MetricCard(
            label: 'Total Clients',
            value: '$totalClients',
            change: '+5% this month',
            isPositive: true,
            icon: Icons.person_outline,
            accentColor: AppTheme.statusSuccess,
          ),
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: EntranceAnimation(
          delay: const Duration(milliseconds: 200),
          child: MetricCard(
            label: 'Active Projects',
            value: '$totalProjects',
            change: '3 new',
            isPositive: true,
            icon: Icons.work_outline,
            accentColor: AppTheme.safetyOrange,
          ),
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: EntranceAnimation(
          delay: const Duration(milliseconds: 300),
          child: MetricCard(
            label: 'Total Revenue',
            value: '₹${(totalRevenue / 1000000).toStringAsFixed(1)}M',
            change: '+18% this month',
            isPositive: true,
            icon: Icons.attach_money,
            accentColor: AppTheme.statusSuccess,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMetricsCardsTablet() {
    final totalLeads = dashboardMetrics['totalLeads'] ?? 0;
    final totalClients = dashboardMetrics['totalClients'] ?? 0;
    final totalProjects = dashboardMetrics['totalProjects'] ?? 0;
    final totalRevenue = dashboardMetrics['totalRevenue'] ?? 0.0;

    return [
      Row(
        children: [
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
        ],
      ),
      const SizedBox(height: AppTheme.spacingMD),
      Row(
        children: [
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
        ],
      ),
    ];
  }

  Widget _buildLeadsPieChart() {
    final leadsByStatus =
        dashboardMetrics['leadsByStatus'] as Map<String, dynamic>? ?? {};
    final isMobile = ResponsiveUtils.isMobile(context);
    final radius = isMobile ? 30.0 : 50.0;
    final centerSpaceRadius = isMobile ? 30.0 : 50.0;
    final titleFontSize = isMobile ? 9.0 : 11.0;

    final data = leadsByStatus.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: isMobile ? '${entry.value}' : '${entry.key}\n${entry.value}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        color: _getStatusColor(entry.key),
      );
    }).toList();

    return ChartCard(
      title: 'Leads by Status',
      subtitle: 'Distribution of leads across different stages',
      height: isMobile ? 250 : 300,
      chart: PieChart(
        PieChartData(
          sections: data,
          centerSpaceRadius: centerSpaceRadius,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildProjectProgressChart() {
    final projectProgress =
        dashboardMetrics['projectProgress'] as List<dynamic>? ?? [];
    final isMobile = ResponsiveUtils.isMobile(context);

    return ChartCard(
      title: 'Project Progress',
      subtitle: 'Projects by status',
      height: isMobile ? 250 : 300,
      chart: SingleChildScrollView(
        child: Column(
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
                      value: ((item['percentage'] as num?) ?? 0.0).toDouble() / 100,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(((item['percentage'] as num?) ?? 0.0).toDouble()),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final monthlyRevenue =
        dashboardMetrics['monthlyRevenue'] as List<dynamic>? ?? [];
    final isMobile = ResponsiveUtils.isMobile(context);

    return ChartCard(
      title: 'Monthly Revenue Trend',
      subtitle: 'Revenue growth over the last 6 months',
      height: isMobile ? 250 : 300,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50000,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: AppTheme.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 40 : 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 10 : 12,
                        ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isMobile ? 30 : 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < monthlyRevenue.length) {
                    return Text(
                      monthlyRevenue[value.toInt()]['month'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isMobile ? 10 : 12,
                          ),
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
