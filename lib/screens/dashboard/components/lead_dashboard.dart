import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/lead.dart';
import '../../../constants.dart';
import '../../../responsive.dart';

class LeadDashboard extends StatelessWidget {
  final List<Lead> leads;
  const LeadDashboard({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    final totalLeads = leads.length;
    final convertedLeads = leads.where((l) => l.status == 'Won').length;
    final conversionRate = totalLeads == 0
        ? 0
        : (convertedLeads / totalLeads * 100).toStringAsFixed(1);
    final totalSalesValue = leads
        .where((l) => l.status == 'Won')
        .fold<double>(0, (sum, l) => sum + (l.budget ?? 0));
    final newCustomers = totalLeads;
    final stageCounts = <String, int>{};
    final repCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final monthlySales = <int, double>{};
    for (var lead in leads) {
      // projectStage field removed
      repCounts[lead.assignedTeam] = (repCounts[lead.assignedTeam] ?? 0) + 1;
      typeCounts[lead.projectType] = (typeCounts[lead.projectType] ?? 0) + 1;
      sourceCounts[lead.sourceString] =
          (sourceCounts[lead.sourceString] ?? 0) + 1;
      final month = lead.createdAt.month;
      if (lead.status == 'Won') {
        monthlySales[month] = (monthlySales[month] ?? 0) + (lead.budget ?? 0);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management Dashboard',
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: defaultPadding),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _MetricCard(title: 'Total Leads', value: totalLeads.toString()),
            _MetricCard(
                title: 'Conversion Rate (%)', value: conversionRate.toString()),
            _MetricCard(
                title: 'Total Sales Value',
                value: '₹${totalSalesValue.toStringAsFixed(0)}'),
            _MetricCard(title: 'New Customers', value: newCustomers.toString()),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
        Responsive(
          mobile: Column(
            children: [
              _PieChartWidget(stageCounts, 'Pipeline by Stage'),
              const SizedBox(height: defaultPadding),
              _PieChartWidget(typeCounts, 'Project Type Distribution'),
              const SizedBox(height: defaultPadding),
              _PieChartWidget(sourceCounts, 'Lead Source Distribution'),
            ],
          ),
          tablet: Row(
            children: [
              Expanded(
                  child: _PieChartWidget(stageCounts, 'Pipeline by Stage')),
              const SizedBox(width: defaultPadding),
              Expanded(
                  child:
                      _PieChartWidget(typeCounts, 'Project Type Distribution')),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(
                  child: _PieChartWidget(stageCounts, 'Pipeline by Stage')),
              const SizedBox(width: defaultPadding),
              Expanded(
                  child:
                      _PieChartWidget(typeCounts, 'Project Type Distribution')),
              const SizedBox(width: defaultPadding),
              Expanded(
                  child: _PieChartWidget(
                      sourceCounts, 'Lead Source Distribution')),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Text(
          'Sales Value by Month',
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 800,
              child: _SalesBarChart(monthlySales),
            ),
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Text(
          'Top Sales Reps',
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: defaultPadding),
        _TopRepsList(repCounts),
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

class _TopRepsList extends StatelessWidget {
  final Map<String, int> data;
  const _TopRepsList(this.data);
  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sorted.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${e.key}: ${e.value} leads'),
                )),
          ],
        ),
      ),
    );
  }
}
