import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/customer.dart';
import '../../../models/customer_role.dart';
import '../../../responsive.dart';
import '../../../services/crm_service.dart';
import '../../../utils/container_styles.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> customers = [];
  List<CustomerRole> customerRoles = [];
  bool isLoading = true;
  String? errorMessage;
  final CRMService _crmService = CRMService();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadCustomerRoles();
  }

  Future<void> _loadCustomerRoles() async {
    try {
      final roles = await _crmService.getCustomerRoles();
      if (mounted) {
        setState(() {
          customerRoles = roles;
        });
      }
    } catch (e) {
      // Silently fail - roles will just not be displayed
      print('Error loading customer roles: $e');
    }
  }

  String _getRoleDescription(int? roleId) {
    if (roleId == null) return 'N/A';
    final role = customerRoles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => CustomerRole(id: 0, name: '', description: 'Unknown'),
    );
    return role.description;
  }


  Future<void> _loadCustomers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedCustomers = await _crmService.getAllCustomers();

      if (mounted) {
        setState(() {
          customers = loadedCustomers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('HandshakeException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data received from server.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('404')) {
      return 'Service not found. Please contact support.';
    } else {
      return 'Failed to load customers. Please try again.';
    }
  }

  Future<void> _refreshCustomers() async {
    await _loadCustomers();
  }

  Future<void> _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: customer),
      ),
    );

    if (result == true) {
      await _refreshCustomers();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text(
              'Are you sure you want to delete "${customer.fullName}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && customer.id != null) {
      try {
        await _crmService.deleteCustomer(customer.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully!')),
          );
          _refreshCustomers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting customer: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Responsive.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Customers",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: defaultPadding,
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddCustomerScreen()),
                                );
                                if (result == true) {
                                  _loadCustomers();
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Customer"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (!Responsive.isDesktop(context))
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {},
                        ),
                      Text(
                        "Customers",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddCustomerScreen()),
                          );

                          if (result == true) {
                            _loadCustomers();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add New Customer"),
                      ),
                    ],
                  ),
            const SizedBox(height: defaultPadding),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadCustomers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              RefreshIndicator(
                onRefresh: _refreshCustomers,
                child: CustomersTable(
                  customers: customers,
                  customerRoles: customerRoles,
                  onEdit: _editCustomer,
                  onDelete: _deleteCustomer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final List<CustomerRole> customerRoles;
  final Function(Customer) onEdit;
  final Function(Customer) onDelete;

  const CustomersTable({
    super.key,
    required this.customers,
    required this.customerRoles,
    required this.onEdit,
    required this.onDelete,
  });

  String _getRoleDescription(int? roleId) {
    if (roleId == null) return 'N/A';
    final role = customerRoles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => CustomerRole(id: 0, name: '', description: 'Unknown'),
    );
    return role.description;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.secondaryBox,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable table columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: defaultPadding,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    headingRowHeight: 56,
                    columns: const [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Created At")),
                    ],
                    rows: customers.map((customer) {
                      return DataRow(
                        cells: [
                          DataCell(Text(customer.id?.toString() ?? 'N/A')),
                          DataCell(
                            Text(
                              customer.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(customer.email)),
                          DataCell(
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: customer.enabled ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.enabled ? 'Enabled' : 'Disabled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_getRoleDescription(customer.roleId))),
                          DataCell(Text(
                            customer.createdAt != null
                                ? '${customer.createdAt!.day}/${customer.createdAt!.month}/${customer.createdAt!.year}'
                                : 'N/A',
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Fixed Actions Column
              Container(
                width: 92,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        "Actions",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    // Rows
                    ...customers.asMap().entries.map((entry) {
                      final customer = entry.value;
                      return Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 18),
                                tooltip: 'Edit Customer',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  onEdit(customer);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                tooltip: 'Delete Customer',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  onDelete(customer);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

