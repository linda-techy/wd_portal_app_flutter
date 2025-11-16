import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/lead.dart';

class LeadManagementDashboard extends StatelessWidget {
  final List<Lead> leads;
  const LeadManagementDashboard({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    final totalLeads = leads.length;
    final convertedLeads = leads.where((l) => l.status == 'Won').length;
    final conversionRate = totalLeads == 0
        ? '0.0'
        : (convertedLeads / totalLeads * 100).toStringAsFixed(1);
    final totalSalesValue = leads
        .where((l) => l.status == 'Won')
        .fold<double>(0, (sum, l) => sum + (l.budget ?? 0));
    final pipelineStages = <String, int>{};
    final typeCounts = <String, int>{};
    final monthlySales = <int, double>{};
    for (var lead in leads) {
      // projectStage field removed
      typeCounts[lead.projectType] = (typeCounts[lead.projectType] ?? 0) + 1;
      final month = lead.createdAt.month;
      if (lead.status == 'Won') {
        monthlySales[month] = (monthlySales[month] ?? 0) + (lead.budget ?? 0);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lead Management Dashboard',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _MetricCard(title: 'Total Leads', value: totalLeads.toString()),
            _MetricCard(title: 'Conversion Rate (%)', value: conversionRate),
            _MetricCard(
                title: 'Total Sales Value',
                value: '₹${totalSalesValue.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
                child: _PieChartWidget(pipelineStages, 'Pipeline by Stage')),
            const SizedBox(width: 16),
            Expanded(
                child:
                    _PieChartWidget(typeCounts, 'Project Type Distribution')),
          ],
        ),
        const SizedBox(height: 32),
        Text('Sales Value by Month',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: _SalesBarChart(monthlySales)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  const _PieChartWidget(this.data, this.title);
  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    data.forEach((key, count) {
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        title: key,
        color: Colors.primaries[sections.length % Colors.primaries.length],
      ));
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: PieChart(PieChartData(sections: sections)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  final Map<int, double> data;
  const _SalesBarChart(this.data);
  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];
    for (int m = 1; m <= 12; m++) {
      barGroups.add(BarChartGroupData(
        x: m,
        barRods: [
          BarChartRodData(
            toY: data[m] ?? 0,
            color: Colors.blue,
          ),
        ],
      ));
    }
    return BarChart(BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
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
              return Text(months[value.toInt() - 1]);
            },
          ),
        ),
      ),
    ));
  }
}
