import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/consumption_report_models.dart';
import 'package:intl/intl.dart';

class MaterialConsumptionScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const MaterialConsumptionScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  State<MaterialConsumptionScreen> createState() => _MaterialConsumptionScreenState();
}

class _MaterialConsumptionScreenState extends State<MaterialConsumptionScreen> {
  final _currencyFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchConsumptionReport(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Material Consumption Report'),
            Text(
              widget.projectName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.deepSlate,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InventoryProvider>().fetchConsumptionReport(widget.projectId),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.fetchConsumptionReport(widget.projectId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final report = provider.consumptionReports;
          if (report == null || report.isEmpty) {
            return const Center(child: Text('No consumption data derived for this project.'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('Material', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Inward\n(Purchased)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right), numeric: true),
                  DataColumn(label: Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right), numeric: true),
                  DataColumn(label: Text('Wastage\n/Theft', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.right), numeric: true),
                  DataColumn(label: Text('Implied\nConsumption', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right), numeric: true),
                ],
                rows: report.map((item) => _buildRow(item)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildRow(MaterialConsumptionReport item) {
    // Highlight if wastage is significant (> 0)
    final bool hasIssues = item.totalVariance > 0;
    
    return DataRow(
      color: hasIssues ? MaterialStateProperty.all(Colors.red[50]) : null,
      cells: [
        DataCell(Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(item.unit)),
        DataCell(Text(_currencyFormat.format(item.totalPurchased))),
        DataCell(Text(_currencyFormat.format(item.currentStock))),
        DataCell(
          item.totalVariance > 0 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(_currencyFormat.format(item.totalVariance), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              )
            : Text(_currencyFormat.format(0)),
        ),
        DataCell(Text(
          _currencyFormat.format(item.impliedConsumption),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
      ],
    );
  }
}
