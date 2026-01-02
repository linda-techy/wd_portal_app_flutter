import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/change_orders/data/models/change_order.dart';
import 'package:admin/features/change_orders/data/services/change_order_service.dart';
import 'package:intl/intl.dart';

class ChangeOrdersScreen extends StatefulWidget {
  final int projectId;

  const ChangeOrdersScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _ChangeOrdersScreenState createState() => _ChangeOrdersScreenState();
}

class _ChangeOrdersScreenState extends State<ChangeOrdersScreen> {
  final ChangeOrderService _service = ChangeOrderService();
  List<ChangeOrder> _changeOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getChangeOrders(widget.projectId);
      setState(() {
        _changeOrders = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddChangeOrderDialog(
        projectId: widget.projectId,
        onSave: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header / Actions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change Orders (${_changeOrders.length})',
                style: AppTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Change Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _changeOrders.isEmpty
                  ? Center(
                      child: Text(
                        'No change orders found.',
                        style: AppTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _changeOrders.length,
                      itemBuilder: (context, index) {
                        return _buildCard(_changeOrders[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(ChangeOrder order) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    Color statusColor;
    
    switch (order.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      case 'PENDING_APPROVAL':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          order.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Amount: ${currencyFormatter.format(order.estimatedAmount)}'),
            if (order.notes != null && order.notes!.isNotEmpty)
              Text('Notes: ${order.notes}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: () {
            // TODO: Navigate to Detail Screen
        },
      ),
    );
  }
}

class AddChangeOrderDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const AddChangeOrderDialog({Key? key, required this.projectId, required this.onSave}) : super(key: key);

  @override
  _AddChangeOrderDialogState createState() => _AddChangeOrderDialogState();
}

class _AddChangeOrderDialogState extends State<AddChangeOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final ChangeOrderService _service = ChangeOrderService();
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newOrder = ChangeOrder(
        projectId: widget.projectId,
        description: _descController.text,
        estimatedAmount: double.parse(_amountController.text),
        notes: _notesController.text,
      );

      await _service.createChangeOrder(newOrder);

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Change Order'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Estimated Amount (₹)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
