import 'package:flutter/material.dart';
import '../../../../utils/error_handler.dart';
import '../../data/models/subcontract_models.dart';
import '../../data/services/subcontract_service.dart';

class RetentionDashboardScreen extends StatefulWidget {
  final int projectId;

  const RetentionDashboardScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _RetentionDashboardScreenState createState() => _RetentionDashboardScreenState();
}

class _RetentionDashboardScreenState extends State<RetentionDashboardScreen> {
  final _service = SubcontractService();
  bool _isLoading = true;
  List<SubcontractWorkOrder> _workOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getProjectWorkOrders(widget.projectId);
      if (mounted) {
        setState(() {
          _workOrders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.handleApiError(context, e);
      }
    }
  }

  void _showReleaseDialog(SubcontractWorkOrder workOrder) {
    final _amountController = TextEditingController();
    final _notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Release Retention for ${workOrder.vendorName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Accumulated: ${workOrder.totalRetentionAccumulated}'),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount to Release'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               try {
                 final amount = double.parse(_amountController.text);
                 if (amount > workOrder.totalRetentionAccumulated) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot release more than accumulated')));
                   return;
                 }
                 
                 final release = RetentionRelease(
                   workOrderId: workOrder.id!,
                   amountReleased: amount,
                   releaseDate: DateTime.now().toIso8601String().split('T')[0],
                   notes: _notesController.text,
                 );
                 
                 await _service.releaseRetention(release);
                 Navigator.pop(ctx);
                 _loadData(); // Refresh
               } catch (e) {
                 ErrorHandler.handleApiError(context, e);
               }
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retention Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _workOrders.length,
              itemBuilder: (context, index) {
                final wo = _workOrders[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text('${wo.workOrderNumber} - ${wo.vendorName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scope: ${wo.scopeDescription}'),
                        Text('Total Retention Held: ${wo.totalRetentionAccumulated}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showReleaseDialog(wo),
                      child: const Text('Release'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

