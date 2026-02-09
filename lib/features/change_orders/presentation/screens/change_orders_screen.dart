import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/change_orders/data/models/change_order.dart';
import 'package:admin/features/change_orders/data/services/change_order_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class ChangeOrdersScreen extends StatefulWidget {
  final int projectId;

  const ChangeOrdersScreen({super.key, required this.projectId});

  @override
  _ChangeOrdersScreenState createState() => _ChangeOrdersScreenState();
}

class _ChangeOrdersScreenState extends State<ChangeOrdersScreen> {
  final ChangeOrderService _service = ChangeOrderService();
  List<ChangeOrder> _changeOrders = [];
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         // Since this is likely a tab view, redirect might be handled by parent or just show error
         await ErrorHandler.handleAuthError(context);
         // Or consistent redirect
         Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isPageLoading = true);
    try {
      final data = await _service.getChangeOrders(widget.projectId);
      setState(() {
        _changeOrders = data;
        _isPageLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load change orders');
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
    return _isPageLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
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
                        backgroundColor: AppTheme.deepSlate,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _changeOrders.isEmpty
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
        onTap: () => _showDetailDialog(order),
      ),
    );
  }
}

  void _showDetailDialog(ChangeOrder order) {
    final currencyFormatter = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 2);
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('Change Order #${order.id ?? '-'}', style: const TextStyle(fontSize: 18))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(order.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(order.description),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(currencyFormatter.format(order.estimatedAmount), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Client Approved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                order.clientApproved ? Icons.check_circle : Icons.cancel,
                                color: order.clientApproved ? Colors.green : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(order.clientApproved ? 'Yes' : 'No'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(order.notes!),
                ],
                if (order.createdAt != null) ...[
                  const Divider(height: 24),
                  Text('Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                if (order.approvedAt != null)
                  Text('Approved: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.approvedAt!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class AddChangeOrderDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const AddChangeOrderDialog({super.key, required this.projectId, required this.onSave});

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
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to create change order');
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

