import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin/constants.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/models/lead.dart';
import 'package:admin/models/client.dart';
import 'package:admin/models/project.dart';
import 'package:admin/utils/container_styles.dart';

class CRMDashboard extends StatefulWidget {
  const CRMDashboard({super.key});

  @override
  _CRMDashboardState createState() => _CRMDashboardState();
}

class _CRMDashboardState extends State<CRMDashboard> {
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

      // Fetch real data from API
      final leadsData = await _crmService.getAllLeads();
      final clientsData = await _crmService.getAllClients();
      final projectsData = await _crmService.getAllProjects();

      // Debug: Print the actual data being fetched
      print('=== API Data Debug ===');
      print('Leads fetched: ${leadsData.length}');
      print('Clients fetched: ${clientsData.length}');
      print('Projects fetched: ${projectsData.length}');

      if (leadsData.isNotEmpty) {
        print('Sample lead: ${leadsData.first.toJson()}');
      }

      setState(() {
        leads = leadsData;
        clients = clientsData;
        projects = projectsData;
        isLoading = false;
      });

      // Calculate real metrics based on API data
      _calculateRealMetrics();
    } catch (e) {
      print('Error fetching API data: $e');
      setState(() {
        isLoading = false;
      });
      // Only use mock data if absolutely no API data could be fetched
      if (leads.isEmpty && clients.isEmpty && projects.isEmpty) {
        print('No API data available, using mock data as fallback');
        _loadMockData();
      } else {
        // If we have some data, calculate metrics from what we have
        print(
            'Using partial API data, calculating metrics from available data');
        _calculateRealMetrics();
      }
    }
  }

  void _calculateRealMetrics() {
    // Calculate total leads
    final totalLeads = leads.length;

    // Calculate leads by status
    final leadsByStatus = <String, int>{};
    for (final lead in leads) {
      final status = (lead.status.isNotEmpty) ? lead.status : 'Unknown';
      leadsByStatus[status] = (leadsByStatus[status] ?? 0) + 1;
    }

    // Calculate total revenue from won leads
    final totalRevenue = leads
        .where((l) => l.status == 'Won')
        .fold<double>(0, (sum, l) => sum + (l.budget ?? 0));

    // Debug: Print calculated metrics
    print('=== Calculated Metrics ===');
    print('Total Leads: $totalLeads');
    print('Leads by Status: $leadsByStatus');
    print('Total Revenue: $totalRevenue');
    print('Total Clients: ${clients.length}');
    print('Total Projects: ${projects.length}');

    // Calculate project progress
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

    // Calculate monthly revenue from won leads
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

    // Calculate team performance
    final teamPerformance = <Map<String, dynamic>>[];
    final salesReps = <String, List<Lead>>{};

    for (final lead in leads) {
      if (lead.assignedTeam.isNotEmpty) {
        salesReps[lead.assignedTeam] = [
          ...(salesReps[lead.assignedTeam] ?? []),
          lead
        ];
      }
    }

    salesReps.forEach((rep, repLeads) {
      final totalRepLeads = repLeads.length;
      final wonLeads = repLeads.where((l) => l.status == 'Won').length;
      final conversion =
          totalRepLeads == 0 ? 0.0 : (wonLeads / totalRepLeads * 100);

      teamPerformance.add({
        'name': rep,
        'leads': totalRepLeads,
        'conversion': conversion,
      });
    });

    // Sort team performance by conversion rate
    teamPerformance.sort((a, b) => b['conversion'].compareTo(a['conversion']));

    setState(() {
      dashboardMetrics = {
        'totalLeads': totalLeads,
        'totalClients': clients.length,
        'totalProjects': projects.length,
        'totalRevenue': totalRevenue,
        'leadsByStatus': leadsByStatus,
        'projectProgress': projectProgress,
        'monthlyRevenue': monthlyRevenue,
        'teamPerformance': teamPerformance,
      };
    });

    print('=== Final Dashboard Metrics ===');
    print('Dashboard Metrics: $dashboardMetrics');
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
        'teamPerformance': [
          {'name': 'Alice Smith', 'leads': 25, 'conversion': 68.0},
          {'name': 'Bob Lee', 'leads': 18, 'conversion': 72.0},
          {'name': 'Carol Johnson', 'leads': 22, 'conversion': 64.0},
          {'name': 'David Brown', 'leads': 15, 'conversion': 80.0},
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CRM Dashboard",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _loadDashboardData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),

                    // Key Metrics Cards
                    _buildMetricsCards(),
                    const SizedBox(height: defaultPadding),

                    // Charts Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          // Stack charts vertically on smaller screens
                          return Column(
                            children: [
                              _buildLeadsPieChart(),
                              const SizedBox(height: defaultPadding),
                              _buildProjectProgressChart(),
                            ],
                          );
                        } else {
                          // Use Row for larger screens
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLeadsPieChart(),
                              ),
                              const SizedBox(width: defaultPadding),
                              Expanded(
                                flex: 2,
                                child: _buildProjectProgressChart(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: defaultPadding),

                    // Revenue Chart
                    _buildRevenueChart(),
                    const SizedBox(height: defaultPadding),

                    // Team Performance
                    _buildTeamPerformanceTable(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Use Wrap for smaller screens
          return Wrap(
            spacing: defaultPadding,
            runSpacing: defaultPadding,
            children: [
              SizedBox(
                width: 200,
                child: _buildMetricCard(
                  'Total Leads',
                  '${dashboardMetrics['totalLeads'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildMetricCard(
                  'Total Clients',
                  '${dashboardMetrics['totalClients'] ?? 0}',
                  Icons.person,
                  Colors.green,
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildMetricCard(
                  'Active Projects',
                  '${dashboardMetrics['totalProjects'] ?? 0}',
                  Icons.work,
                  Colors.orange,
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildMetricCard(
                  'Total Revenue',
                  '₹${(dashboardMetrics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          );
        } else {
          // Use Row for larger screens
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Leads',
                  '${dashboardMetrics['totalLeads'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                child: _buildMetricCard(
                  'Total Clients',
                  '${dashboardMetrics['totalClients'] ?? 0}',
                  Icons.person,
                  Colors.green,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                child: _buildMetricCard(
                  'Active Projects',
                  '${dashboardMetrics['totalProjects'] ?? 0}',
                  Icons.work,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                child: _buildMetricCard(
                  'Total Revenue',
                  '₹${(dashboardMetrics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      constraints: const BoxConstraints(minWidth: 150),
      decoration: ContainerStyles.primaryBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsPieChart() {
    final leadsByStatus =
        dashboardMetrics['leadsByStatus'] as Map<String, dynamic>? ?? {};
    final data = leadsByStatus.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        color: _getStatusColor(entry.key),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.successBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Leads by Status",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: data,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectProgressChart() {
    final projectProgress =
        dashboardMetrics['projectProgress'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.infoBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Project Progress",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: defaultPadding),
          ...projectProgress.map((item) => _buildProgressBar(
                item['name'],
                item['percentage'].toDouble(),
                item['count'],
              )),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$count (${percentage.toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[600],
            valueColor:
                AlwaysStoppedAnimation<Color>(_getProgressColor(percentage)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final monthlyRevenue =
        dashboardMetrics['monthlyRevenue'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.warningBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Revenue Trend",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < monthlyRevenue.length) {
                          return Text(monthlyRevenue[value.toInt()]['month']);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyRevenue.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value['revenue'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPerformanceTable() {
    final teamPerformance =
        dashboardMetrics['teamPerformance'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.purpleBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Team Performance",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: defaultPadding),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Team Member')),
                DataColumn(label: Text('Leads')),
                DataColumn(label: Text('Conversion %')),
                DataColumn(label: Text('Performance')),
              ],
              rows: teamPerformance.map((member) {
                return DataRow(
                  cells: [
                    DataCell(Text(member['name'])),
                    DataCell(Text('${member['leads']}')),
                    DataCell(
                        Text('${member['conversion'].toStringAsFixed(1)}%')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPerformanceColor(member['conversion']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPerformanceLabel(member['conversion']),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blue;
      case 'Contacted':
        return Colors.orange;
      case 'Qualified':
        return Colors.yellow;
      case 'Proposal Sent':
        return Colors.purple;
      case 'Negotiation':
        return Colors.indigo;
      case 'Won':
        return Colors.green;
      case 'Lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.yellow;
    return Colors.red;
  }

  Color _getPerformanceColor(double conversion) {
    if (conversion >= 75) return Colors.green;
    if (conversion >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceLabel(double conversion) {
    if (conversion >= 75) return 'Excellent';
    if (conversion >= 60) return 'Good';
    return 'Needs Improvement';
  }
}
