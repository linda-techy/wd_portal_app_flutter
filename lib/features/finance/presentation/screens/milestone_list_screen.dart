import 'package:admin/features/finance/data/models/billing_models.dart';
import 'package:admin/services/finance_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MilestoneListScreen extends StatefulWidget {
  final int projectId;

  const MilestoneListScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _MilestoneListScreenState createState() => _MilestoneListScreenState();
}

class _MilestoneListScreenState extends State<MilestoneListScreen> {
  final FinanceService _financeService = FinanceService();
  List<ProjectMilestone> _milestones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final milestones = await _financeService.getProjectMilestones(widget.projectId);
      setState(() {
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading milestones: $e')));
    }
  }

  Future<void> _showMilestoneDialog({ProjectMilestone? milestone}) async {
    final _formKey = GlobalKey<FormState>();
    String name = milestone?.name ?? '';
    double amount = milestone?.amount ?? 0.0;
    double? percentage = milestone?.milestonePercentage;
    String? description = milestone?.description;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(milestone == null ? 'Add Milestone' : 'Edit Milestone'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    initialValue: amount.toString(),
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => amount = double.parse(value!),
                  ),
                  TextFormField(
                    initialValue: percentage?.toString() ?? '',
                    decoration: InputDecoration(labelText: 'Percentage (%)'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => percentage = value!.isNotEmpty ? double.parse(value) : null,
                  ),
                   TextFormField(
                    initialValue: description ?? '',
                    decoration: InputDecoration(labelText: 'Description'),
                    onSaved: (value) => description = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    Map<String, dynamic> data = {
                      'projectId': widget.projectId,
                      'name': name,
                      'amount': amount,
                      'milestonePercentage': percentage,
                      'description': description,
                    };
                    
                    if (milestone != null) {
                         // Update
                         await _financeService.updateMilestone(ProjectMilestone(
                             id: milestone.id,
                             projectId: widget.projectId,
                             name: name,
                             amount: amount,
                             milestonePercentage: percentage,
                             description: description,
                             status: milestone.status,
                             dueDate: milestone.dueDate,
                         ));
                    } else {
                        // Create
                        await _financeService.createMilestone(ProjectMilestone(
                             projectId: widget.projectId,
                             name: name,
                             amount: amount,
                             milestonePercentage: percentage,
                             description: description,
                        ));
                    }
                    
                    Navigator.pop(context);
                    _loadMilestones();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateInvoice(ProjectMilestone milestone) async {
      try {
          await _financeService.generateInvoiceForMilestone(milestone.id!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice generated successfully')));
          _loadMilestones();
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating invoice: $e')));
      }
  }

  Future<void> _markCompleted(ProjectMilestone milestone) async {
       try {
           final updatedMilestone = ProjectMilestone(
               id: milestone.id,
               projectId: milestone.projectId,
               name: milestone.name,
               amount: milestone.amount,
               milestonePercentage: milestone.milestonePercentage,
               description: milestone.description,
               status: 'COMPLETED',
               dueDate: milestone.dueDate,
               completedDate: DateTime.now(),
               invoiceId: milestone.invoiceId
           );
           await _financeService.updateMilestone(updatedMilestone);
            _loadMilestones();
       } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
            children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Project Milestones', style: Theme.of(context).textTheme.titleLarge),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Milestone'),
                        onPressed: () => _showMilestoneDialog(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: _milestones.length,
                      itemBuilder: (context, index) {
                        final milestone = _milestones[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(milestone.name),
                            subtitle: Text('${NumberFormat.currency(symbol: '₹').format(milestone.amount)} - ${milestone.status}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (milestone.status == 'PENDING')
                                    IconButton(
                                        icon: Icon(Icons.check_circle_outline, color: Colors.green),
                                        tooltip: 'Mark Completed',
                                        onPressed: () => _markCompleted(milestone),
                                    ),
                                if (milestone.status == 'COMPLETED' && milestone.invoiceId == null)
                                    IconButton(
                                      icon: Icon(Icons.receipt_long, color: Colors.blue),
                                      tooltip: 'Generate Invoice',
                                      onPressed: () => _generateInvoice(milestone),
                                    ),
                                if (milestone.invoiceId != null)
                                    Chip(label: Text('Invoiced')),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _showMilestoneDialog(milestone: milestone),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
            ],
          ),
    );
  }
}

