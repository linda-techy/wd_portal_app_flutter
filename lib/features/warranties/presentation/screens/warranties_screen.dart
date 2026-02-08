import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/warranties/data/models/project_warranty.dart';
import 'package:admin/features/warranties/data/services/warranty_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class WarrantiesScreen extends StatefulWidget {
  final int projectId;

  const WarrantiesScreen({super.key, required this.projectId});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  final WarrantyService _service = WarrantyService();
  List<ProjectWarranty> _warranties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         await ErrorHandler.handleAuthError(context);
         if (mounted) {
           Navigator.of(context).pushReplacementNamed('/login');
         }
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getWarranties(widget.projectId);
      setState(() {
        _warranties = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
         await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load warranties');
      }
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddWarrantyDialog(
        projectId: widget.projectId,
        onSave: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Warranties',
                style: AppTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Add Warranty'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _warranties.isEmpty
                  ? Center(child: Text('No warranties found.', style: AppTheme.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _warranties.length,
                      itemBuilder: (context, index) {
                        return _buildCard(_warranties[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(ProjectWarranty warranty) {
    final isActive = warranty.status == 'ACTIVE';
    final now = DateTime.now();
    final isExpired = warranty.endDate != null && warranty.endDate!.isBefore(now);
    
    // Status visual logic
    Color statusColor = Colors.grey;
    String displayStatus = warranty.status;
    
    if (isActive) {
        if (isExpired) {
            statusColor = Colors.red;
            displayStatus = 'EXPIRED';
        } else {
            statusColor = Colors.green;
        }
    } else {
        if (warranty.status == 'VOID') statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.shield_outlined, color: statusColor),
        ),
        title: Text(
          warranty.componentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(warranty.providerName ?? 'Unknown Provider'),
        trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(4),
            ),
            child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (warranty.startDate != null)
                        Text('Start Date: ${DateFormat('MMM dd, yyyy').format(warranty.startDate!)}'),
                    if (warranty.endDate != null)
                        Text('End Date: ${DateFormat('MMM dd, yyyy').format(warranty.endDate!)}'),
                    const SizedBox(height: 8),
                    if (warranty.coverageDetails != null)
                        Text('Coverage: ${warranty.coverageDetails}'),
                    if (warranty.description != null)
                        Text('Notes: ${warranty.description}', style: const TextStyle(color: Colors.grey)),
                ],
            ),
          )
        ],
      ),
    );
  }
}

class AddWarrantyDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const AddWarrantyDialog({super.key, required this.projectId, required this.onSave});

  @override
  State<AddWarrantyDialog> createState() => _AddWarrantyDialogState();
}

class _AddWarrantyDialogState extends State<AddWarrantyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _componentController = TextEditingController();
  final _providerController = TextEditingController();
  final _coverageController = TextEditingController();
  final WarrantyService _service = WarrantyService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newWarranty = ProjectWarranty(
        projectId: widget.projectId,
        componentName: _componentController.text,
        providerName: _providerController.text,
        coverageDetails: _coverageController.text,
        startDate: _startDate,
        endDate: _endDate,
      );

      await _service.createWarranty(newWarranty);

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to create warranty');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Warranty'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _componentController,
                decoration: const InputDecoration(labelText: 'Component (e.g. Roof, HVAC)'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _providerController,
                decoration: const InputDecoration(labelText: 'Provider / Vendor'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                    Expanded(
                        child: InputDatePickerFormField(
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            fieldLabelText: 'Start Date',
                            onDateSaved: (d) => _startDate = d,
                        ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: InputDatePickerFormField(
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            fieldLabelText: 'End Date',
                            onDateSaved: (d) => _endDate = d,
                        ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coverageController,
                decoration: const InputDecoration(labelText: 'Coverage Details'),
                maxLines: 2,
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
          onPressed: _isSaving ? null : () {
              _formKey.currentState!.save();
              _submit();
          },
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}

