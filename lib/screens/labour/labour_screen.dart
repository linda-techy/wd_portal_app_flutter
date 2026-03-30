import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/labour_models.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/services/labour_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class LabourScreen extends StatelessWidget {
  const LabourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabourProvider()..fetch(),
      child: Consumer<LabourProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Labour'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('labour:create')) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildLabourList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, LabourProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search labour...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, LabourProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All Types',
          isSelected: provider.filters['labourType'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Mason',
          isSelected: provider.filters['labourType'] == 'MASON',
          onTap: () => provider.updateFilter('labourType', 'MASON'),
        ),
        _buildFilterChip(
          context,
          label: 'Carpenter',
          isSelected: provider.filters['labourType'] == 'CARPENTER',
          onTap: () => provider.updateFilter('labourType', 'CARPENTER'),
        ),
        _buildFilterChip(
          context,
          label: 'Electrician',
          isSelected: provider.filters['labourType'] == 'ELECTRICIAN',
          onTap: () => provider.updateFilter('labourType', 'ELECTRICIAN'),
        ),
        _buildFilterChip(
          context,
          label: 'Plumber',
          isSelected: provider.filters['labourType'] == 'PLUMBER',
          onTap: () => provider.updateFilter('labourType', 'PLUMBER'),
        ),
        const SizedBox(width: 16),
        _buildFilterChip(
          context,
          label: 'Active',
          isSelected: provider.filters['isActive'] == true,
          onTap: () => provider.updateFilter('isActive', true),
          color: AppTheme.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLabourList(BuildContext context, LabourProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No labour found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final labour = provider.items[index];
          return _buildLabourCard(context, labour);
        },
      ),
    );
  }

  Widget _buildLabourCard(BuildContext context, Labour labour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, labour),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      labour.name.isNotEmpty
                          ? labour.name[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labour.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labour.tradeType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: labour.active
                          ? AppTheme.statusSuccess
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.phone,
                    label: labour.phone,
                  ),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${labour.dailyWage.toStringAsFixed(2)}/day',
                    color: AppTheme.statusSuccess,
                  ),
                  _buildInfoChip(
                    icon: Icons.work,
                    label: labour.tradeType,
                  ),
                  if (labour.emergencyContact != null)
                    _buildInfoChip(
                      icon: Icons.contact_phone,
                      label: labour.emergencyContact!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, LabourProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Labour labour) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(labour.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('Trade', labour.tradeType),
            _infoRow('Phone', labour.phone),
            _infoRow('Daily Wage', '₹${labour.dailyWage.toStringAsFixed(0)}'),
            if (labour.idProofType != null) _infoRow('ID Type', labour.idProofType!),
            if (labour.idProofNumber != null) _infoRow('ID Number', labour.idProofNumber!),
            if (labour.emergencyContact != null) _infoRow('Emergency', labour.emergencyContact!),
            _infoRow('Status', labour.active ? 'Active' : 'Inactive'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateLabourDialog(
        onCreated: () {
          Provider.of<LabourProvider>(context, listen: false).fetch();
        },
      ),
    );
  }
}

class _CreateLabourDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateLabourDialog({required this.onCreated});

  @override
  State<_CreateLabourDialog> createState() => _CreateLabourDialogState();
}

class _CreateLabourDialogState extends State<_CreateLabourDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();

  String _tradeType = 'MASON';
  String? _idProofType;
  bool _isSaving = false;

  final List<String> _trades = [
    'MASON', 'CARPENTER', 'PLUMBER', 'ELECTRICIAN', 'PAINTER',
    'WELDER', 'FITTER', 'HELPER', 'SUPERVISOR', 'OTHER',
  ];

  final List<String> _idTypes = ['AADHAAR', 'PAN', 'VOTER_ID', 'DRIVING_LICENSE'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = LabourService();
      await service.createLabour({
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'tradeType': _tradeType,
        'dailyWage': double.parse(_wageCtrl.text),
        if (_idProofType != null) 'idProofType': _idProofType,
        if (_idNumberCtrl.text.isNotEmpty) 'idProofNumber': _idNumberCtrl.text,
        if (_emergencyCtrl.text.isNotEmpty) 'emergencyContact': _emergencyCtrl.text,
        'active': true,
      });

      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Labour added'), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Labour'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _tradeType,
                  decoration: const InputDecoration(labelText: 'Trade Type'),
                  items: _trades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _tradeType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _wageCtrl,
                  decoration: const InputDecoration(labelText: 'Daily Wage *', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _idProofType,
                  decoration: const InputDecoration(labelText: 'ID Proof Type'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ..._idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (v) => setState(() => _idProofType = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idNumberCtrl,
                  decoration: const InputDecoration(labelText: 'ID Proof Number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyCtrl,
                  decoration: const InputDecoration(labelText: 'Emergency Contact'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

