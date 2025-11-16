import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/models/client.dart';
import 'package:admin/services/crm_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  _ClientsScreenState createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final CRMService _crmService = CRMService();
  List<Client> clients = [];
  List<Client> filteredClients = [];
  bool isLoading = true;
  String searchQuery = '';
  String statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final loadedClients = await _crmService.getAllClients();
      setState(() {
        clients = loadedClients;
        filteredClients = loadedClients;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Load mock data for demonstration
      _loadMockData();
    }
  }

  void _loadMockData() {
    final mockClients = [
      Client(
        id: '1',
        clientCode: 'CL001',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@email.com',
        phone: '+91 98765 43210',
        whatsapp: '+91 98765 43210',
        address: '123 Main Street',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        source: 'Website',
        assignedTo: 'Alice Smith',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Client(
        id: '2',
        clientCode: 'CL002',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@email.com',
        phone: '+91 87654 32109',
        whatsapp: '+91 87654 32109',
        address: '456 Oak Avenue',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        source: 'Referral',
        assignedTo: 'Bob Lee',
        status: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),
      Client(
        id: '3',
        clientCode: 'CL003',
        firstName: 'Mike',
        lastName: 'Johnson',
        email: 'mike.johnson@email.com',
        phone: '+91 76543 21098',
        whatsapp: '+91 76543 21098',
        address: '789 Pine Road',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        source: 'Social Media',
        assignedTo: 'Carol Johnson',
        status: 'Inactive',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
    ];

    setState(() {
      clients = mockClients;
      filteredClients = mockClients;
    });
  }

  void _filterClients() {
    setState(() {
      filteredClients = clients.where((client) {
        final matchesSearch = client.fullName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            client.email?.toLowerCase().contains(searchQuery.toLowerCase()) ==
                true ||
            client.phone?.contains(searchQuery) == true ||
            client.clientCode
                    ?.toLowerCase()
                    .contains(searchQuery.toLowerCase()) ==
                true;

        final matchesStatus =
            statusFilter == 'All' || client.status == statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Clients Management",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditClientDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Search and Filter Bar
            _buildSearchAndFilterBar(),
            const SizedBox(height: defaultPadding),

            // Clients Data Table
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildClientsDataTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (value) {
              searchQuery = value;
              _filterClients();
            },
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: statusFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: ['All', 'Active', 'Inactive', 'Prospect']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                statusFilter = value!;
                _filterClients();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientsDataTable() {
    return DataTable(
      columnSpacing: 12,
      horizontalMargin: 12,
      columns: const [
        DataColumn(
          label: Text('Client Code'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Name'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Contact'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Location'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Source'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Assigned To'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Status'),
          numeric: false,
        ),
        DataColumn(
          label: Text('Actions'),
          numeric: false,
        ),
      ],
      rows: filteredClients.map((client) {
        return DataRow(
          cells: [
            DataCell(Text(client.clientCode ?? '')),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    client.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (client.email != null)
                    Text(
                      client.email!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (client.phone != null) Text(client.phone!),
                  if (client.whatsapp != null)
                    Text(
                      'WhatsApp: ${client.whatsapp}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            DataCell(
              Text('${client.city ?? ''}, ${client.state ?? ''}'),
            ),
            DataCell(Text(client.source ?? '')),
            DataCell(Text(client.assignedTo ?? '')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(client.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  client.status ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _showAddEditClientDialog(client: client),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(client),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Inactive':
        return Colors.red;
      case 'Prospect':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showAddEditClientDialog({Client? client}) {
    showDialog(
      context: context,
      builder: (context) => AddEditClientDialog(
        client: client,
        onSave: (Client newClient) async {
          try {
            if (client == null) {
              await _crmService.saveClient(newClient);
            } else {
              await _crmService.updateClient(client.id!, newClient);
            }
            _loadClients();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Client ${client == null ? 'added' : 'updated'} successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _crmService.deleteClient(client.id!);
                _loadClients();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddEditClientDialog extends StatefulWidget {
  final Client? client;
  final Function(Client) onSave;

  const AddEditClientDialog({super.key, this.client, required this.onSave});

  @override
  _AddEditClientDialogState createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends State<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  String _source = 'Website';
  String _status = 'Active';
  String _assignedTo = 'Alice Smith';

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.client?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.client?.lastName ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _whatsappController =
        TextEditingController(text: widget.client?.whatsapp ?? '');
    _addressController =
        TextEditingController(text: widget.client?.address ?? '');
    _cityController = TextEditingController(text: widget.client?.city ?? '');
    _stateController = TextEditingController(text: widget.client?.state ?? '');
    _pincodeController =
        TextEditingController(text: widget.client?.pincode ?? '');

    if (widget.client != null) {
      _source = widget.client!.source ?? 'Website';
      _status = widget.client!.status ?? 'Active';
      _assignedTo = widget.client!.assignedTo ?? 'Alice Smith';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.client == null ? 'Add New Client' : 'Edit Client'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value?.isEmpty == true
                          ? 'First name is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value?.isEmpty == true
                          ? 'Last name is required'
                          : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Email is required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Phone is required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(labelText: 'WhatsApp'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _source,
                      decoration: const InputDecoration(labelText: 'Source'),
                      items: [
                        'Website',
                        'Referral',
                        'Social Media',
                        'Advertisement',
                        'Other'
                      ]
                          .map((source) => DropdownMenuItem(
                              value: source, child: Text(source)))
                          .toList(),
                      onChanged: (value) => setState(() => _source = value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['Active', 'Inactive', 'Prospect']
                          .map((status) => DropdownMenuItem(
                              value: status, child: Text(status)))
                          .toList(),
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _assignedTo,
                decoration: const InputDecoration(labelText: 'Assigned To'),
                items: [
                  'Alice Smith',
                  'Bob Lee',
                  'Carol Johnson',
                  'David Brown'
                ]
                    .map((member) =>
                        DropdownMenuItem(value: member, child: Text(member)))
                    .toList(),
                onChanged: (value) => setState(() => _assignedTo = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveClient,
          child: Text(widget.client == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final client = Client(
        id: widget.client?.id,
        clientCode: widget.client?.clientCode ??
            'CL${DateTime.now().millisecondsSinceEpoch}',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        whatsapp: _whatsappController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        source: _source,
        assignedTo: _assignedTo,
        status: _status,
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(client);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
