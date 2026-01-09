import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../../constants.dart';

class LeadsSummaryCard extends StatelessWidget {
  final int totalLeads;
  final Map<String, int> leadsBySource;

  const LeadsSummaryCard({
    super.key,
    required this.totalLeads,
    required this.leadsBySource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Leads Summary",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(Icons.bar_chart, color: Colors.white54),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Text(
            "$totalLeads Total Leads",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                sections: _getSections(),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          ...leadsBySource.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.white70)),
                    Text("${e.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    // Generate colors dynamically or use a predefined palette
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
    ];
    
    int index = 0;
    return leadsBySource.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 20,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
