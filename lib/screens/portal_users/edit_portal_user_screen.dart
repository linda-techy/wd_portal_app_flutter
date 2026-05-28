import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/portal_user.dart';
import '../../models/role.dart';
import '../../services/crm_service.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/motion_button.dart';
import '../../widgets/animations/shake_widget.dart';
import '../../utils/motion_toast.dart';

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
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _designationController;
  late final TextEditingController _departmentController;
  late bool _enabled;
  int? _roleId;
  List<PortalRole> _roles = [];
  bool _isLoadingRoles = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _shouldShake = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _whatsappController = TextEditingController(text: widget.user.whatsapp ?? '');
    _designationController = TextEditingController(text: widget.user.designation ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
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
        MotionToast.show(
          context,
          message: 'Error loading roles: $e',
          isError: true,
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
    _phoneController.dispose();
    _whatsappController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _shouldShake = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shouldShake = false);
      });
      return;
    }

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
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        designation: _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      );

      await _crmService.updatePortalUser(widget.user.id!, user);

        if (mounted) {
          MotionToast.show(
            context,
            message: 'User updated successfully!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
    } catch (e) {
        if (mounted) {
          MotionToast.show(
            context,
            message: 'Error updating user: $e',
            isError: true,
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
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: ShakeWidget(
            shouldShake: _shouldShake,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 0),
                    child: Text(
                      'User Information',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
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
                        child: EntranceAnimation(
                          delay: const Duration(milliseconds: 100),
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
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: EntranceAnimation(
                          delay: const Duration(milliseconds: 150),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Email
                EntranceAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
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
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Password
                EntranceAnimation(
                  delay: const Duration(milliseconds: 250),
                  child: StatefulBuilder(
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
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Role Dropdown
                EntranceAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: DropdownButtonFormField<int>(
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
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Enabled Switch
                EntranceAnimation(
                  delay: const Duration(milliseconds: 350),
                  child: SwitchListTile(
                    title: const Text('Enabled'),
                    subtitle: const Text('User account status'),
                    value: _enabled,
                    onChanged: (value) {
                      setState(() {
                        _enabled = value;
                      });
                    },
                  ),
                ),
                // Contact & role details — API accepts these on update; the form
                // previously didn't expose them.
                const SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: _designationController,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
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
                    MotionButton(
                      isEnabled: !_isLoading,
                      onPressed: _saveUser,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUser,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update User'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
      ),
    ),
    ),
    );
  }
}


