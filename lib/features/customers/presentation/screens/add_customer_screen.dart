import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/constants/customer_type_constants.dart';
import '../../data/models/customer.dart';
import 'package:admin/models/customer_role.dart';
import '../../data/services/customer_service.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/validators.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // New Business Fields Controllers
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _leadSourceController = TextEditingController();
  final _notesController = TextEditingController();

  String _customerType = CustomerTypeConstants.defaultValue;
  int? _roleId;
  List<CustomerRole> _customerRoles = [];
  bool _isLoadingRoles = false;

  bool _isPageLoading = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadRoles();
  }

  Future<void> _verifyAuthAndLoadRoles() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
      return;
    }
    
    await _loadCustomerRoles();
  }

  Future<void> _loadCustomerRoles() async {
    try {
      setState(() => _isLoadingRoles = true);
      final roles = await _customerService.getCustomerRoles();
      if (mounted) {
        setState(() {
          _customerRoles = roles;
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

    setState(() => _isLoading = true);

    try {
      if (_roleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a role'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final customer = Customer(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text.trim(),
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

      await _customerService.createCustomer(customer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error creating customer');
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
        title: const Text('Add Customer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) =>
                                  Validators.password(value, required: true),
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
                                  // The Enabled toggle was removed: CustomerCreateRequest
                                  // has no `enabled` field, so the value was silently
                                  // dropped server-side and the toggle was misleading.
                                  // Replaced with Customer Type — the API already
                                  // accepts customer_type but the form never set it.
                                  child: DropdownButtonFormField<String>(
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
                                ),
                              ],
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
              'Save Customer',
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


