import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/customer.dart';
import '../../../models/customer_role.dart';
import '../../../services/crm_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late bool _enabled;
  int? _roleId;
  List<CustomerRole> _customerRoles = [];
  bool _isLoadingRoles = false;

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
    _enabled = customer.enabled;
    _roleId = customer.roleId;
    _loadCustomerRoles();
  }

  Future<void> _loadCustomerRoles() async {
    try {
      setState(() => _isLoadingRoles = true);
      final roles = await _crmService.getCustomerRoles();
      if (mounted) {
        setState(() {
          _customerRoles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading roles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      );

      await _crmService.updateCustomer(widget.customer.id!, customer);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      body: _isLoading
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
                                  validator: (value) {
                                    // Only validate if password is provided
                                    if (value != null && value.isNotEmpty) {
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                    }
                                    return null;
                                  },
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

