import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/task_models.dart';
import '../../services/task_service.dart';

class TaskAlertDashboardScreen extends StatefulWidget {
  const TaskAlertDashboardScreen({super.key});

  @override
  State<TaskAlertDashboardScreen> createState() =>
      _TaskAlertDashboardScreenState();
}

class _TaskAlertDashboardScreenState extends State<TaskAlertDashboardScreen> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<TaskAlertModel> _recentAlerts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _taskService.getAlertStats();
      final recent = await _taskService.getRecentAlerts();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentAlerts = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _triggerManualAlerts() async {
    try {
      await _taskService.triggerAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert check triggered successfully')),
        );
        _loadData(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading dashboard: $_error',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Alerts & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          // Admin only trigger - we could check role here but Service enforces it too
          IconButton(
            icon: const Icon(Icons.notification_important),
            tooltip: 'Trigger Manual Alert Check',
            onPressed: _triggerManualAlerts,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1, // Pie Chart
                  child: _buildSeverityChart(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2, // Recent Alerts
                  child: _buildRecentAlertsList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    // Assuming stats structure: { "CRITICAL": 5, "HIGH": 2, "MEDIUM": 10 }
    // Or whatever the backend returns.
    // The previous implementation returned `TaskAlertService.getAlertStats(days)`
    // which returns Map<String, Long>. keys are AlertSeverity names.

    final critical = _stats?['CRITICAL'] ?? 0;
    final high = _stats?['HIGH'] ?? 0;
    final medium = _stats?['MEDIUM'] ?? 0;

    return Row(
      children: [
        _buildStatCard('Critical Alerts', critical.toString(), Colors.red,
            Icons.warning_amber),
        const SizedBox(width: 16),
        _buildStatCard('High Priority', high.toString(), Colors.orange,
            Icons.priority_high),
        const SizedBox(width: 16),
        _buildStatCard('Medium Priority', medium.toString(), Colors.blue,
            Icons.notifications_none),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChart() {
    final critical = (_stats?['CRITICAL'] ?? 0).toDouble();
    final high = (_stats?['HIGH'] ?? 0).toDouble();
    final medium = (_stats?['MEDIUM'] ?? 0).toDouble();
    final total = critical + high + medium;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No alerts in the last 7 days')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Alert Severity Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    if (critical > 0)
                      PieChartSectionData(
                          color: Colors.red,
                          value: critical,
                          title:
                              '${(critical / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    if (high > 0)
                      PieChartSectionData(
                          color: Colors.orange,
                          value: high,
                          title: '${(high / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    if (medium > 0)
                      PieChartSectionData(
                          color: Colors.blue,
                          value: medium,
                          title:
                              '${(medium / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend('Critical', Colors.red),
            _buildChartLegend('High', Colors.orange),
            _buildChartLegend('Medium', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecentAlertsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Alerts Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_recentAlerts.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No recent alerts'),
              ))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentAlerts.length,
                separatorBuilder: (ctx, index) => const Divider(),
                itemBuilder: (ctx, index) {
                  final alert = _recentAlerts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getSeverityColor(alert.severity).withOpacity(0.1),
                      child: Icon(
                        _getSeverityIcon(alert.severity),
                        color: _getSeverityColor(alert.severity),
                        size: 20,
                      ),
                    ),
                    title: Text(alert.taskTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(alert.message),
                        const SizedBox(height: 4),
                        Text(
                          '${alert.alertType} • ${alert.sentAt.toString().substring(0, 16)}', // Simple format
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Icons.warning_amber;
      case 'HIGH':
        return Icons.priority_high;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }
}
