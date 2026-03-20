import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer.dart';
import '../../data/services/customer_service.dart';
import 'edit_customer_screen.dart';
import 'package:admin/utils/error_handler.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final Customer? initialCustomer;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final CustomerService _customerService = CustomerService();
  Customer? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      // Show list-item data instantly; silently fetch full record in background
      // so roleId and all fields are up-to-date when the user taps Edit.
      _customer = widget.initialCustomer;
      _isLoading = false;
      _refreshSilently();
    } else {
      _loadCustomer();
    }
  }

  /// Fetches the full customer record without showing the loading spinner.
  /// Used when we already have partial data from the list (initialCustomer).
  Future<void> _refreshSilently() async {
    try {
      final customer =
          await _customerService.getCustomerById(widget.customerId);
      if (mounted) {
        setState(() {
          _customer = customer;
          _error = null;
        });
      }
    } catch (_) {
      // Silent failure — we still have initialCustomer to display.
    }
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customer =
          await _customerService.getCustomerById(widget.customerId);
      if (mounted) {
        setState(() {
          _customer = customer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load customer details');
      }
    }
  }

  Future<void> _navigateToEdit() async {
    if (_customer == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: _customer!),
      ),
    );

    if (result == true && mounted) {
      // Refresh customer data after edit
      await _loadCustomer();
    }
  }

  Future<void> _deleteCustomer() async {
    if (_customer == null || _customer!.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${_customer!.fullName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _customerService.deleteCustomer(_customer!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return to list with refresh flag
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(
            context,
            e,
            defaultMessage: 'Failed to delete customer',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.fullName ?? 'Customer Details'),
        actions: [
          if (_customer != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
              tooltip: 'Edit Customer',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCustomer,
              tooltip: 'Delete Customer',
              color: Colors.red,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomer,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _customer == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCustomer,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _customer == null
                  ? const Center(child: Text('Customer not found'))
                  : RefreshIndicator(
                      onRefresh: _loadCustomer,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: defaultPadding),
                            _buildBasicInfoCard(),
                            const SizedBox(height: defaultPadding),
                            _buildContactInfoCard(),
                            const SizedBox(height: defaultPadding),
                            _buildBusinessInfoCard(),
                            const SizedBox(height: defaultPadding),
                            _buildMetadataCard(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Text(
                _customer!.fullName.isNotEmpty
                    ? _customer!.fullName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customer!.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_customer!.companyName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _customer!.companyName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildStatusBadge(_customer!.enabled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        enabled ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            const Divider(),
            const SizedBox(height: defaultPadding),
            _buildInfoRow('Email', _customer!.email, Icons.email),
            if (_customer!.roleId != null)
              _buildInfoRow(
                  'Role ID', _customer!.roleId.toString(), Icons.badge),
            _buildInfoRow(
                'Projects', _customer!.projectCount.toString(), Icons.folder),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final hasContactInfo = _customer!.phone != null ||
        _customer!.whatsappNumber != null ||
        _customer!.address != null;

    if (!hasContactInfo) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contact Information'),
            const Divider(),
            const SizedBox(height: defaultPadding),
            if (_customer!.phone != null)
              _buildInfoRow('Phone', _customer!.phone!, Icons.phone),
            if (_customer!.whatsappNumber != null)
              _buildInfoRow(
                  'WhatsApp', _customer!.whatsappNumber!, Icons.message),
            if (_customer!.address != null)
              _buildInfoRow('Address', _customer!.address!, Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    final hasBusinessInfo = _customer!.companyName != null ||
        _customer!.gstNumber != null ||
        _customer!.leadSource != null ||
        _customer!.notes != null;

    if (!hasBusinessInfo) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Business Information'),
            const Divider(),
            const SizedBox(height: defaultPadding),
            if (_customer!.companyName != null)
              _buildInfoRow(
                  'Company Name', _customer!.companyName!, Icons.business),
            if (_customer!.gstNumber != null)
              _buildInfoRow('GST Number', _customer!.gstNumber!, Icons.receipt),
            if (_customer!.leadSource != null)
              _buildInfoRow(
                  'Lead Source', _customer!.leadSource!, Icons.source),
            if (_customer!.notes != null)
              _buildInfoRow('Notes', _customer!.notes!, Icons.note,
                  maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Metadata'),
            const Divider(),
            const SizedBox(height: defaultPadding),
            if (_customer!.createdAt != null)
              _buildInfoRow(
                'Created At',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(_customer!.createdAt!),
                Icons.calendar_today,
              ),
            if (_customer!.updatedAt != null)
              _buildInfoRow(
                'Updated At',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(_customer!.updatedAt!),
                Icons.update,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
