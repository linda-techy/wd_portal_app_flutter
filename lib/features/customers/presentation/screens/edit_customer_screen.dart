import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/constants/customer_type_constants.dart';
import '../../data/models/customer.dart';
import 'package:admin/models/customer_role.dart';
import '../../data/services/customer_service.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/validators.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // New Business Fields Controllers
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _companyNameController;
  late TextEditingController _gstNumberController;
  late TextEditingController _leadSourceController;
  late TextEditingController _notesController;

  late bool _enabled;
  late String _customerType;
  int? _roleId;
  List<CustomerRole> _customerRoles = [];
  bool _isLoadingRoles = false;

  bool _isPageLoading = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _firstNameController = TextEditingController(text: customer.firstName);
    _lastNameController = TextEditingController(text: customer.lastName);
    _emailController = TextEditingController(text: customer.email);
    // Password field is intentionally left empty - user can enter new password or leave empty to keep current
    _passwordController = TextEditingController();
    
    _phoneController = TextEditingController(text: customer.phone ?? '');
    _whatsappController =
        TextEditingController(text: customer.whatsappNumber ?? '');
    _addressController = TextEditingController(text: customer.address ?? '');
    _companyNameController =
        TextEditingController(text: customer.companyName ?? '');
    _gstNumberController =
        TextEditingController(text: customer.gstNumber ?? '');
    _leadSourceController =
        TextEditingController(text: customer.leadSource ?? '');
    _notesController = TextEditingController(text: customer.notes ?? '');

    _enabled = customer.enabled;
    _customerType = customer.customerType;
    _roleId = customer.roleId;
    _loadCustomerRoles();
  }

  Future<void> _loadCustomerRoles() async {
    try {
      setState(() => _isLoadingRoles = true);

      // Fetch roles and fresh customer data in parallel.
      // The list API may omit roleId — always get full customer to pre-select the role.
      final futures = await Future.wait([
        _customerService.getCustomerRoles(),
        if (widget.customer.id != null && _roleId == null)
          _customerService.getCustomerById(widget.customer.id!)
        else
          Future.value(null),
      ]);

      final roles = futures[0] as List<CustomerRole>;
      final freshCustomer = futures[1] as Customer?;

      if (mounted) {
        setState(() {
          _customerRoles = roles;
          // Use roleId from fresh API fetch when the passed customer had none
          if (_roleId == null && freshCustomer?.roleId != null) {
            _roleId = freshCustomer!.roleId;
          }
          _isLoadingRoles = false;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoles = false;
          _isPageLoading = false;
        });
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error loading roles');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _gstNumberController.dispose();
    _leadSourceController.dispose();
    _notesController.dispose();
    
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (widget.customer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid customer ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_roleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Only include password if user entered a new one
      final passwordText = _passwordController.text.trim();
      final customer = Customer(
        id: widget.customer.id,
        email: _emailController.text.trim(),
        enabled: _enabled,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: passwordText.isNotEmpty ? passwordText : null,
        roleId: _roleId,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
        gstNumber: _gstNumberController.text.trim().isEmpty ? null : _gstNumberController.text.trim(),
        leadSource: _leadSourceController.text.trim().isEmpty ? null : _leadSourceController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        customerType: _customerType,
      );

      await _customerService.updateCustomer(widget.customer.id!, customer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error updating customer');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Customer: ${widget.customer.fullName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCustomer,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isPageLoading 
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Information'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'First Name *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value?.isEmpty == true
                                            ? 'First name is required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: defaultPadding),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Last Name *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value?.isEmpty == true
                                            ? 'Last name is required'
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty == true) {
                                  return 'Email is required';
                                }
                                if (value != null &&
                                    !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: defaultPadding),
                            StatefulBuilder(
                              builder: (context, setStateLocal) {
                                return TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter new password (leave empty to keep current)',
                                    helperText: 'Leave empty to keep the current password',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _passwordController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(_obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off),
                                            onPressed: () {
                                              setStateLocal(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  obscureText: _obscurePassword,
                                  onChanged: (value) {
                                    setStateLocal(() {
                                      // Trigger rebuild to show/hide visibility icon
                                    });
                                  },
                                  validator: (value) =>
                                    Validators.password(value, required: false),
                                );
                              },
                            ),
                            const SizedBox(height: defaultPadding),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Role *',
                                      border: OutlineInputBorder(),
                                    ),
                                    isExpanded: true,
                                    value: _isLoadingRoles || _customerRoles.isEmpty
                                        ? null
                                        : (_roleId != null && 
                                           _customerRoles.any((r) => r.id == _roleId))
                                            ? _roleId
                                            : null,
                                    items: _isLoadingRoles
                                        ? [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                            )
                                          ]
                                        : _customerRoles.map((role) {
                                            return DropdownMenuItem<int>(
                                              value: role.id,
                                              child: Text(role.description),
                                            );
                                          }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _roleId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Role is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: defaultPadding),
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Enabled'),
                                    value: _enabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _enabled = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            // Customer Type — the API accepts customer_type but the
                            // form previously never set it (all customers defaulted
                            // to 'individual'). Now matches the Lead form's dropdown.
                            DropdownButtonFormField<String>(
                              value: _customerType,
                              decoration: const InputDecoration(
                                labelText: 'Customer Type',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: CustomerTypeConstants.dropdownItems,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _customerType = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: defaultPadding),
                    
                    _buildSectionHeader('Contact Details'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: Validators.phone,
                                  ),
                                ),
                                const SizedBox(width: defaultPadding),
                                Expanded(
                                  child: TextFormField(
                                    controller: _whatsappController,
                                    decoration: const InputDecoration(
                                      labelText: 'WhatsApp Number',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.message),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: Validators.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),

                    _buildSectionHeader('Business Information'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _companyNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Company Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.business),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: defaultPadding),
                                Expanded(
                                  child: TextFormField(
                                    controller: _gstNumberController,
                                    decoration: const InputDecoration(
                                      labelText: 'GST Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    validator: Validators.gst,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _leadSourceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Lead Source',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.source),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            ),
            onPressed: _isLoading ? null : _saveCustomer,
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}


