import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/portal_user.dart';
import '../../models/role.dart';
import '../../services/crm_service.dart';

class EditPortalUserScreen extends StatefulWidget {
  final PortalUser user;

  const EditPortalUserScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditPortalUserScreen> createState() => _EditPortalUserScreenState();
}

class _EditPortalUserScreenState extends State<EditPortalUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late bool _enabled;
  int? _roleId;
  List<PortalRole> _roles = [];
  bool _isLoadingRoles = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _enabled = widget.user.enabled;
    _roleId = widget.user.roleId;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() => _isLoadingRoles = true);
      final roles = await _crmService.getPortalRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading roles: $e'),
            backgroundColor: AppTheme.statusError,
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

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = PortalUser(
        id: widget.user.id,
        email: _emailController.text.trim(),
        enabled: _enabled,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        roleId: _roleId,
      );

      await _crmService.updatePortalUser(widget.user.id!, user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully!'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: AppTheme.statusError,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Portal User'),
      ),
      body: AdaptiveContainer(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Information',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingLG),
                
                // First Name and Last Name Row
                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          hintText: 'Enter first name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          hintText: 'Enter last name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  desktop: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            hintText: 'Enter first name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            hintText: 'Enter last name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Enter email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Password
                StatefulBuilder(
                  builder: (context, setState) {
                    return TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Leave empty to keep current password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Role Dropdown
                DropdownButtonFormField<int>(
                  value: _roleId,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    hintText: _isLoadingRoles ? 'Loading roles...' : 'Select role',
                    suffixIcon: _isLoadingRoles 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  items: _isLoadingRoles
                      ? []
                      : _roles.map((role) {
                          return DropdownMenuItem<int>(
                            value: role.id,
                            child: Text(role.name),
                          );
                        }).toList(),
                  onChanged: _isLoadingRoles
                      ? null
                      : (value) {
                          setState(() {
                            _roleId = value;
                          });
                        },
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Enabled Switch
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('User account status'),
                  value: _enabled,
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // Save Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUser,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

