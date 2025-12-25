import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/team_member.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/models/role.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/utils/india_location_data.dart';
import 'package:admin/constants/project_type_constants.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/motion_button.dart';
import '../../widgets/animations/shake_widget.dart';
import '../../utils/motion_toast.dart';

class AddCustomerProjectScreen extends StatefulWidget {
  const AddCustomerProjectScreen({super.key});

  @override
  State<AddCustomerProjectScreen> createState() =>
      _AddCustomerProjectScreenState();
}

class _AddCustomerProjectScreenState extends State<AddCustomerProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _sqfeetController = TextEditingController();
  final _leadSearchController = TextEditingController();

  DateTime? _startDate;
  bool _shouldShake = false;

  DateTime? _endDate;
  String? _projectPhase = 'Design'; // Default to Design
  String? _projectType = ProjectTypeConstants.defaultValue;
  String? _state = 'Kerala'; // Default to Kerala
  String? _district = 'Thrissur'; // Default to Thrissur
  Lead? _selectedLead;
  List<Lead> _leads = [];
  List<Lead> _filteredLeads = [];
  bool _isLoadingLeads = false;
  bool _isLoading = false;
  bool _showLeadDropdown = false;
  final FocusNode _leadSearchFocusNode = FocusNode();

  // Customer Selection
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoadingCustomers = false;

  // Team Members
  List<TeamMember> _teamMembers = [];
  List<TeamMember> _selectedTeamMembers = [];
  Set<String> _adminIds = {}; // Track admin IDs to prevent deselection
  bool _isLoadingTeamMembers = false;

  final List<String> _projectPhases = [
    'Design',
    'Construction',
    'Completed',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _leadSearchFocusNode.addListener(() {
      if (!_leadSearchFocusNode.hasFocus) {
        // Only close dropdown when losing focus if no lead is selected
        // Use a longer delay to ensure tap events on dropdown items are processed first
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted &&
              !_leadSearchFocusNode.hasFocus &&
              _selectedLead == null) {
            setState(() {
              _showLeadDropdown = false;
            });
          }
        });
      } else {
        // When field gets focus, show dropdown
        setState(() {
          _showLeadDropdown = true;
          // Show all leads when field gets focus
          if (_leadSearchController.text.isEmpty) {
            _filteredLeads = _leads;
          }
        });
      }
    });
    _locationController.addListener(_updateProjectName);
  }

  void _updateProjectName() {
    if (_selectedCustomer != null) {
      final customerName = '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}'.trim();
      final location = _locationController.text.trim();
      _nameController.text = location.isNotEmpty ? '$customerName - $location' : customerName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sqfeetController.dispose();
    _leadSearchController.dispose();
    _leadSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch all required data sequentially to avoid any potential race conditions
      final leads = await _crmService.getAllLeads();
      final portalUsers = await _crmService.getAllPortalUsers();
      final customers = await _crmService.getAllCustomers();

      final roles = await _crmService.getPortalRoles();
      final customerRoles = await _crmService.getCustomerRoles();
      
      // Create Role Maps
      final Map<int, String> portalRoleMap = {
        for (var role in roles) if (role.id != null) role.id!: role.name
      };
      final Map<int, String> customerRoleMap = {
        for (var role in customerRoles) if (role.id != null) role.id!: role.name
      };
      
      // Find admin role ID for Portal Users
      int? adminRoleId;
      try {
        final adminRole = roles.firstWhere(
          (r) => r.code?.toLowerCase() == 'admin' || r.name.toLowerCase() == 'admin',
        );
        adminRoleId = adminRole.id;
      } catch (_) {
        // Admin role not found, ignore
      }

      // Find admin role ID for Customers
      int? customerAdminRoleId;
      try {
        final customerAdminRole = customerRoles.firstWhere(
          (r) => r.name.toLowerCase() == 'admin',
        );
        customerAdminRoleId = customerAdminRole.id;
      } catch (_) {
        // Customer Admin role not found, ignore
      }

      // Combine PortalUsers and Customers into TeamMembers
      final List<TeamMember> allTeamMembers = [];
      
      // Add Portal Users
      for (var user in portalUsers) {
        allTeamMembers.add(TeamMember(
          id: user.id.toString(),
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          type: 'PORTAL',
          designation: portalRoleMap[user.roleId] ?? '',
        ));
      }
      
      // Add Customers
      for (var customer in customers) {
        allTeamMembers.add(TeamMember(
          id: customer.id.toString(),
          firstName: customer.firstName,
          lastName: customer.lastName,
          email: customer.email,
          type: 'CUSTOMER',
          designation: customerRoleMap[customer.roleId] ?? '',
        ));
      }

      // Identify Admins to auto-select
      final List<TeamMember> autoSelectedAdmins = [];
      
      if (adminRoleId != null) {
        // Add Portal Admins
        for (var user in portalUsers) {
          if (user.roleId == adminRoleId) {
            autoSelectedAdmins.add(TeamMember(
              id: user.id.toString(),
              firstName: user.firstName,
              lastName: user.lastName,
              email: user.email,
              type: 'PORTAL',
              designation: portalRoleMap[user.roleId] ?? '',
            ));
            if (user.id != null) {
              _adminIds.add('PORTAL_${user.id}');
            }
          }
        }
      }

      // Add Customer Admins (Independent check)
      if (customerAdminRoleId != null) {
        for (var customer in customers) {
          if (customer.roleId == customerAdminRoleId) {
            autoSelectedAdmins.add(TeamMember(
              id: customer.id.toString(),
              firstName: customer.firstName,
              lastName: customer.lastName,
              email: customer.email,
              type: 'CUSTOMER',
              designation: customerRoleMap[customer.roleId] ?? '',
            ));
            if (customer.id != null) {
              _adminIds.add('CUSTOMER_${customer.id}');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _leads = leads;
          _filteredLeads = leads;
          _customers = customers;
          _teamMembers = allTeamMembers;
          _selectedTeamMembers = autoSelectedAdmins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MotionToast.show(
          context,
          message: 'Error loading data: $e',
          isError: true,
        );
      }
    }
  }

  void _filterLeads(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLeads = _leads;
      } else {
        _filteredLeads = _leads.where((lead) {
          final searchLower = query.toLowerCase();
          return lead.name.toLowerCase().contains(searchLower) ||
              lead.leadId.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Auto-set end date to 10 months from start date
          _endDate = DateTime(picked.year, picked.month + 10, picked.day);
        } else {
          if (_startDate == null || picked.isAfter(_startDate!)) {
            _endDate = picked;
          } else {
            MotionToast.show(
              context,
              message: 'End date must be after start date',
              isError: true,
            );
          }
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _shouldShake = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shouldShake = false);
      });
      return;
    }

    if (_selectedLead == null) {
      MotionToast.show(
        context,
        message: 'Please select a lead',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final project = CustomerProject(
        id: null, // Let backend generate ID
        name: _nameController.text.trim(),
        progress: null, // Initial progress is 0/null
        projectPhase: _projectPhase,
        projectType: _projectType,
        state: _state ?? 'Kerala',
        district: _district ?? 'Thrissur',
        startDate: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim(),
        leadId: int.tryParse(_selectedLead!.leadId),
        customerId: _selectedCustomer?.id,
        sqfeet: double.tryParse(_sqfeetController.text) ?? 0.0,
        teamMembers: _selectedTeamMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _crmService.createCustomerProject(project);

      if (mounted) {
        MotionToast.show(
          context,
          message: 'Project created successfully!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        MotionToast.show(
          context,
          message: 'Failed to create project: ${e.toString()}',
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
        title: const Text('Add Customer Project'),
      ),
      body: AdaptiveContainer(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
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
                    'Project Information',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),

                // Customer Selection
                EntranceAnimation(
                  delay: const Duration(milliseconds: 50),
                  child: DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    decoration: InputDecoration(
                      labelText: 'Customer *',
                      hintText: _isLoading ? 'Loading customers...' : 'Select customer',
                      suffixIcon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(2.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    items: _isLoading
                        ? []
                        : _customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer,
                              child: Text('${customer.firstName} ${customer.lastName}'),
                            );
                          }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (Customer? newValue) {
                            setState(() {
                              _selectedCustomer = newValue;
                              if (newValue != null) {
                                _updateProjectName();
                              }
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a customer';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Location (Moved to 2nd position)
                EntranceAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location *',
                      hintText: 'Enter project location',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Project Type
                EntranceAnimation(
                  delay: const Duration(milliseconds: 150),
                  child: DropdownButtonFormField<String>(
                    value: _projectType,
                    decoration: const InputDecoration(
                      labelText: 'Project Type',
                      hintText: 'Select project type',
                    ),
                    items: ProjectTypeConstants.formDropdownItems,
                    onChanged: (value) {
                      setState(() {
                        _projectType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a project type';
                      }
                      return null;
                    },
                  ),
                ),

                // Name
                EntranceAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project Name *',
                      hintText: 'Enter project name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Project name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Info: Project code will be auto-generated
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: AppTheme.statusInfoBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border:
                        Border.all(color: AppTheme.statusInfo.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: AppTheme.statusInfo),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          'Project code will be auto-generated',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.statusInfo,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Project Phase
                EntranceAnimation(
                  delay: const Duration(milliseconds: 225),
                  child: DropdownButtonFormField<String>(
                    value: _projectPhase,
                    decoration: const InputDecoration(
                      labelText: 'Project Phase *',
                      hintText: 'Select phase',
                    ),
                    items: _projectPhases.map((phase) {
                      return DropdownMenuItem(
                        value: phase,
                        child: Text(phase),
                      );
                    }).toList(),
                    onChanged: null, // Disable selection
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Project phase is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                
                // State and District Row
                EntranceAnimation(
                  delay: const Duration(milliseconds: 250),
                  child: ResponsiveLayout(
                    mobile: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _state,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            hintText: 'Select state',
                          ),
                          isExpanded: true,
                          items: IndiaLocationData.states.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return IndiaLocationData.states.map((state) {
                              return Text(
                                state,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }).toList();
                          },
                          onChanged: (value) {
                            setState(() {
                              _state = value;
                              _district = 'Thrissur'; // Reset district to default when state changes
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        DropdownButtonFormField<String>(
                          value: _district,
                          decoration: const InputDecoration(
                            labelText: 'District',
                            hintText: 'Select district',
                          ),
                          isExpanded: true,
                          items: (_state != null
                                  ? IndiaLocationData.getDistricts(_state!)
                                  : <String>[])
                              .map<DropdownMenuItem<String>>((district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(
                                district,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return (_state != null
                                    ? IndiaLocationData.getDistricts(_state!)
                                    : <String>[])
                                .map((district) {
                              return Text(
                                district,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }).toList();
                          },
                          onChanged: _state != null
                              ? (value) {
                                  setState(() {
                                    _district = value;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    desktop: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _state,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              hintText: 'Select state',
                            ),
                            isExpanded: true,
                            items: IndiaLocationData.states.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return IndiaLocationData.states.map((state) {
                                return Text(
                                  state,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }).toList();
                            },
                            onChanged: (value) {
                              setState(() {
                                _state = value;
                                _district = 'Thrissur'; // Reset district to default when state changes
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _district,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              hintText: 'Select district',
                            ),
                            isExpanded: true,
                            items: (_state != null
                                    ? IndiaLocationData.getDistricts(_state!)
                                    : <String>[])
                                .map<DropdownMenuItem<String>>((district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(
                                  district,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return (_state != null
                                      ? IndiaLocationData.getDistricts(_state!)
                                      : <String>[])
                                  .map((district) {
                                return Text(
                                  district,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }).toList();
                            },
                            onChanged: _state != null
                                ? (value) {
                                    setState(() {
                                      _district = value;
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Start Date and End Date Row (Only visible for Construction phase)
                if (_projectPhase == 'Construction')
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: ResponsiveLayout(
                      mobile: Column(
                        children: [
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                hintText: 'Select start date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                    : 'Select start date',
                                style: TextStyle(
                                  color: _startDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textTertiary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                hintText: 'Select end date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                    : 'Select end date',
                                style: TextStyle(
                                  color: _endDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      desktop: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  hintText: 'Select start date',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                          .format(_startDate!)
                                      : 'Select start date',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  hintText: 'Select end date',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                      : 'Select end date',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_projectPhase == 'Construction')
                  const SizedBox(height: AppTheme.spacingMD),
                const SizedBox(height: AppTheme.spacingMD),

                // Project Phase (Progress defaults to 0, shown as info)
                EntranceAnimation(
                  delay: const Duration(milliseconds: 350),
                  child: DropdownButtonFormField<String>(
                    value: _projectPhase,
                    decoration: const InputDecoration(
                      labelText: 'Project Phase *',
                      hintText: 'Select phase',
                    ),
                    items: _projectPhases.map((phase) {
                      return DropdownMenuItem(
                        value: phase,
                        child: Text(phase),
                      );
                    }).toList(),
                    onChanged: null, // Disable selection
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Project phase is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),



                // Lead Selection (Searchable Dropdown)
                EntranceAnimation(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lead *',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      _buildLeadSearchDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Team Members Selection
                EntranceAnimation(
                  delay: const Duration(milliseconds: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      _buildTeamMemberSelection(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMD),

                // Sq Feet
                EntranceAnimation(
                  delay: const Duration(milliseconds: 500),
                  child: TextFormField(
                    controller: _sqfeetController,
                    decoration: const InputDecoration(
                      labelText: 'Square Feet',
                      hintText: 'Enter area in sqft',
                    ),
                    keyboardType: TextInputType.number,
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
                      onPressed: _saveProject,
                      child: ElevatedButton(
                        onPressed: null, // MotionButton handles the tap
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Project'),
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

  Widget _buildLeadSearchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _leadSearchController,
          focusNode: _leadSearchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search by lead ID or name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _leadSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _leadSearchController.clear();
                        _filterLeads('');
                        _selectedLead = null;
                        _showLeadDropdown = true;
                        _filteredLeads = _leads;
                      });
                      _leadSearchFocusNode.requestFocus();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _filterLeads(value);
            setState(() {
              _showLeadDropdown = true;
            });
          },
          onTap: () {
            setState(() {
              _showLeadDropdown = true;
              // Show all leads when clicking on empty field or when no lead is selected
              if (_leadSearchController.text.isEmpty || _selectedLead == null) {
                _filteredLeads = _leads;
                _filterLeads('');
              }
            });
            // Request focus to ensure dropdown stays visible
            _leadSearchFocusNode.requestFocus();
          },
        ),
        // Dropdown with filtered results - only show when focused or clicked
        if (_showLeadDropdown) ...[
          const SizedBox(height: AppTheme.spacingSM),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: _isLoadingLeads
                  ? const Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMD),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredLeads.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Text(
                            'No leads found',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _filteredLeads.length,
                          itemBuilder: (context, index) {
                            final lead = _filteredLeads[index];
                            final isSelected =
                                _selectedLead?.leadId == lead.leadId;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                // Prevent focus listener from interfering
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _selectedLead = lead;
                                    _leadSearchController.text =
                                        '${lead.leadId} - ${lead.name}';
                                    _showLeadDropdown = false;
                                  });
                                  // Unfocus after a small delay to allow state update
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      _leadSearchFocusNode.unfocus();
                                    }
                                  });
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingMD),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBlue.withOpacity(0.1)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderLight,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${lead.leadId}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          Text(
                                            lead.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedLead != null &&
                                        _selectedLead!.leadId == lead.leadId) ...[
                                      const SizedBox(height: AppTheme.spacingSM),
                                      Container(
                                        padding: const EdgeInsets.all(
                                            AppTheme.spacingSM),
                                        decoration: BoxDecoration(
                                          color: AppTheme.statusSuccessBg,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppTheme.radiusSM),
                                          border: Border.all(
                                            color: AppTheme.statusSuccess
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                size: 16,
                                                color:
                                                    AppTheme.statusSuccess),
                                            const SizedBox(
                                                width: AppTheme.spacingSM),
                                            const Text(
                                              'Selected',
                                              style: TextStyle(
                                                color:
                                                    AppTheme.statusSuccess,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamMemberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showTeamMemberSelectionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSM,
              vertical: AppTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedTeamMembers.isEmpty
                      ? Text(
                          'Select Team Members',
                          style: TextStyle(color: AppTheme.textTertiary),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedTeamMembers.map((member) {
                            return Chip(
                              label: Text(member.fullName),
                              onDeleted: _adminIds.contains('${member.type}_${member.id}')
                                  ? null 
                                  : () {
                                      setState(() {
                                        _selectedTeamMembers.remove(member);
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTeamMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Team Members'),
              content: SizedBox(
                width: double.maxFinite,
                child: _isLoadingTeamMembers
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final isSelected = _selectedTeamMembers.contains(member);
                          final isAdmin = _adminIds.contains('${member.type}_${member.id}');
                          
                          return CheckboxListTile(
                            title: Text(
                              '${member.fullName} (${member.type == 'PORTAL' ? 'Portal User' : 'Customer'})',
                              style: TextStyle(
                                color: member.type == 'PORTAL'
                                    ? AppTheme.textPrimary
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                            subtitle: null,
                            value: isSelected,
                            onChanged: isAdmin 
                                ? null // Disable interactions for admins
                                : (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedTeamMembers.add(member);
                                      } else {
                                        _selectedTeamMembers
                                            .removeWhere((m) => m.id == member.id);
                                      }
                                    });
                                    // Update parent state as well
                                    this.setState(() {});
                                  },
                            // Visual cue for disabled state
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: Text(
                              member.designation ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Rebuild parent widget to show updated chips
      setState(() {});
    });
  }
}
