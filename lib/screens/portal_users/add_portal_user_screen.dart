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

class AddPortalUserScreen extends StatefulWidget {
  const AddPortalUserScreen({super.key});

  @override
  State<AddPortalUserScreen> createState() => _AddPortalUserScreenState();
}

class _AddPortalUserScreenState extends State<AddPortalUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  // Removed: PortalUserCreateRequest has no `enabled` field, so the toggle's
  // value was silently dropped server-side. Edit form keeps the toggle (the
  // Update DTO does accept `enabled`).
  int? _roleId;
  List<PortalRole> _roles = [];
  bool _isLoadingRoles = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _shouldShake = false;

  @override
  void initState() {
    super.initState();
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
      String? trimOrNull(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();
      final user = PortalUser(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text.trim(),
        roleId: _roleId,
        phone: trimOrNull(_phoneController),
        whatsapp: trimOrNull(_whatsappController),
        designation: trimOrNull(_designationController),
        department: trimOrNull(_departmentController),
      );

      await _crmService.createPortalUser(user);

      if (mounted) {
        MotionToast.show(
          context,
          message: 'User created successfully!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        MotionToast.show(
          context,
          message: 'Error creating user: $e',
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
        title: const Text('Add Portal User'),
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
                      EntranceAnimation(
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
                      const SizedBox(height: AppTheme.spacingMD),
                      EntranceAnimation(
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
                          labelText: 'Password *',
                          hintText: 'Enter password',
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
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
                // Contact & role details — the API already accepts these
                // (phone / whatsapp / designation / department) but the form
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
                        onPressed: null, // MotionButton handles the tap
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create User'),
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


