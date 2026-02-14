import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/team_member.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/utils/india_location_data.dart';
import 'package:admin/constants/project_type_constants.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/motion_button.dart';
import '../../widgets/animations/shake_widget.dart';
import '../../utils/motion_toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/utils/error_handler.dart';

class EditCustomerProjectScreen extends StatefulWidget {
  final CustomerProject project;

  const EditCustomerProjectScreen({
    super.key,
    required this.project,
  });

  @override
  State<EditCustomerProjectScreen> createState() =>
      _EditCustomerProjectScreenState();
}

class _EditCustomerProjectScreenState extends State<EditCustomerProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _codeController;
  late final TextEditingController _sqfeetController;

  late final TextEditingController _leadSearchController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _projectPhase;
  String? _projectType;
  String? _contractType;
  final List<Map<String, String>> _contractTypeOptions = [
    {'value': 'TURNKEY', 'label': 'Turnkey (Material + Labor)'},
    {'value': 'LABOR_ONLY', 'label': 'Labor Only'},
    {'value': 'ITEM_RATE', 'label': 'Item Rate'},
    {'value': 'COST_PLUS', 'label': 'Cost Plus (Cost + Margin)'},
  ];

  String? _state;

  String? _district;
  int? _selectedLeadId;
  Lead? _selectedLead;
  List<Lead> _leads = [];
  List<Lead> _filteredLeads = [];

  // Master loading flag for Data-First pattern
  bool _isPageLoading = true;
  bool _isLoading = false; // For save operation
  bool _showLeadDropdown = false;
  bool _shouldShake = false;
  final FocusNode _leadSearchFocusNode = FocusNode();

  // Project Manager
  TeamMember? _selectedProjectManager;



  // Customer Selection
  Customer? _selectedCustomer;
  List<Customer> _customers = [];

  // Team Members
  List<TeamMember> _teamMembers = [];
  List<TeamMember> _selectedTeamMembers = [];
  Set<String> _adminIds = {};
  bool _isLoadingTeamMembers = false;

  final List<String> _projectPhases = [
    'Planning',
    'Design',
    'Construction',
    'Completed',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _locationController = TextEditingController(text: widget.project.location);
    _codeController = TextEditingController(text: widget.project.code ?? '');
    _sqfeetController = TextEditingController(
      text: widget.project.sqfeet != null
          ? widget.project.sqfeet!.toStringAsFixed(2)
          : '',
    );
    _latitudeController = TextEditingController(text: widget.project.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.project.longitude?.toString() ?? '');

    _leadSearchController = TextEditingController();

    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;

    // Validate project phase - ensure it exists in the list
    final projectPhase = widget.project.projectPhase;
    if (projectPhase != null && projectPhase.isNotEmpty) {
      // Try exact match first
      if (_projectPhases.contains(projectPhase)) {
        _projectPhase = projectPhase;
      } else {
        // Try case-insensitive match
        try {
          _projectPhase = _projectPhases.firstWhere(
            (phase) => phase.toLowerCase() == projectPhase.toLowerCase(),
          );
        } catch (e) {
          // No match found, set to null
          _projectPhase = null;
        }
      }
    } else {
      _projectPhase = null;
    }



    _projectType = widget.project.projectType;
    _contractType = widget.project.contractType ?? 'TURNKEY';


    // Validate state - ensure it exists in the list (try case-insensitive match)
    final state = widget.project.state;
    if (state != null && state.isNotEmpty) {
      // Try exact match first
      if (IndiaLocationData.states.contains(state)) {
        _state = state;
      } else {
        // Try case-insensitive match
        try {
          _state = IndiaLocationData.states.firstWhere(
            (s) => s.toLowerCase() == state.toLowerCase(),
          );
        } catch (e) {
          // No match found, set to null
          _state = null;
        }
      }
    } else {
      _state = null;
    }

    // Validate district - ensure it exists for the selected state
    // Default to "Thrissur" if district is null
    final district = widget.project.district;
    if (_state != null && district != null) {
      final districts = IndiaLocationData.getDistricts(_state!);
      _district = districts.contains(district) ? district : 'Thrissur';
    } else {
      // Default to "Thrissur" if district is null
      _district = 'Thrissur';
    }

    _selectedLeadId = widget.project.leadId;

    _verifyAuthAndLoadData();

    _leadSearchFocusNode.addListener(() {
      if (!_leadSearchFocusNode.hasFocus) {
        // Only close dropdown when losing focus if no lead is selected
        // Use a longer delay to ensure tap events on dropdown items are processed first
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_leadSearchFocusNode.hasFocus && _selectedLead == null) {
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

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        MotionToast.show(context, message: 'Please login to continue', isError: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
      return;
    }
    
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      // _isPageLoading is already true from initialization
      
      // Fetch all required data sequentially
      final leads = await _crmService.getAllLeads();
      final portalUsers = await _crmService.getAllPortalUsers();
      final customers = await _crmService.getAllCustomers();

      final roles = await _crmService.getPortalRoles();
      final customerRoles = await _crmService.getCustomerRoles();

      // Create Role Maps
      final Map<int, String> portalRoleMap = {
        for (var role in roles) role.id: role.name
      };
      final Map<int, String> customerRoleMap = {
        for (var role in customerRoles) role.id: role.name
      };



      // Filter for Project Managers (Portal Users)
       final allPortalUsersMember = portalUsers.map((user) => TeamMember(
        id: user.id.toString(),
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        type: 'PORTAL',
        designation: portalRoleMap[user.roleId] ?? '',
      )).toList();


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
      final Set<String> adminIds = {};
      
      if (adminRoleId != null) {
        // Add Portal Admins
        for (var user in portalUsers) {
          if (user.roleId == adminRoleId) {
            final adminMember = TeamMember(
              id: user.id.toString(),
              firstName: user.firstName,
              lastName: user.lastName,
              email: user.email,
              type: 'PORTAL',
              designation: portalRoleMap[user.roleId] ?? '',
            );
            autoSelectedAdmins.add(adminMember);
            if (adminMember.id != null) {
              adminIds.add('PORTAL_${adminMember.id}');
            }
          }
        }
      }
      
      // Add Customer Admins (Independent check)
      if (customerAdminRoleId != null) {
        for (var customer in customers) {
          if (customer.roleId == customerAdminRoleId) {
            final adminMember = TeamMember(
              id: customer.id.toString(),
              firstName: customer.firstName,
              lastName: customer.lastName,
              email: customer.email,
              type: 'CUSTOMER',
              designation: customerRoleMap[customer.roleId] ?? '',
            );
            autoSelectedAdmins.add(adminMember);
            if (adminMember.id != null) {
              adminIds.add('CUSTOMER_${adminMember.id}');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _leads = leads;
          _filteredLeads = leads;
          _customers = customers;
          
          // Pre-select Project Manager
          // _potentialProjectManagers removed as it was unused
          if (widget.project.projectManagerId != null) {
            try {
              _selectedProjectManager = allPortalUsersMember.firstWhere((m) => m.id == widget.project.projectManagerId.toString() && m.type == 'PORTAL');
            } catch (_) {
              // PM not found in list
            }
          }

          
          // Pre-select customer
          if (widget.project.customerId != null) {
            try {
              _selectedCustomer = customers.firstWhere(
                (c) => c.id == widget.project.customerId,
              );
            } catch (_) {
              // Customer not found
            }
          }

          // Find and set the selected lead if leadId exists
          if (_selectedLeadId != null) {
            try {
              _selectedLead = leads.firstWhere(
                (lead) => int.tryParse(lead.leadId) == _selectedLeadId,
              );
              if (_selectedLead != null) {
                _leadSearchController.text =
                    '${_selectedLead!.leadId} - ${_selectedLead!.name}';
              }
            } catch (e) {
              // Lead not found - leave _selectedLead as null
              _selectedLead = null;
            }
          }


          _teamMembers = allTeamMembers;
          
          // Pre-select team members (existing + admins)
          final Set<String> selectedIds = {};
          final List<TeamMember> finalSelectedMembers = [];

          // Add existing members if they exist in the new list
          if (widget.project.teamMembers != null) {
            for (var member in widget.project.teamMembers!) {
              try {
                final freshMember = allTeamMembers.firstWhere((m) => m.id == member.id);
                if (freshMember.id != null && selectedIds.add(freshMember.id!)) {
                  finalSelectedMembers.add(freshMember);
                }
              } catch (_) {
                // Member not found in current list
              }
            }
          }

          // Add auto-selected admins if not already selected
          for (var admin in autoSelectedAdmins) {
            if (admin.id != null && selectedIds.add(admin.id!)) {
              finalSelectedMembers.add(admin);
            }
          }

          _selectedTeamMembers = finalSelectedMembers;
          _adminIds = adminIds;
          _isLoadingTeamMembers = false;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPageLoading = false;
        });
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error loading data');
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

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _codeController.dispose();
    _sqfeetController.dispose();

    _leadSearchController.dispose();
    _leadSearchFocusNode.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            MotionToast.show(context, message: 'Location permission denied', isError: true);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          MotionToast.show(context, message: 'Location permissions are permanently denied', isError: true);
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        MotionToast.show(context, message: 'Location captured successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        MotionToast.show(context, message: 'Failed to get location: $e', isError: true);
      }
    }
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

    if (widget.project.id == null) {
      MotionToast.show(
        context,
        message: 'Invalid project ID',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert leadId from String to int
      int? leadIdInt;
      if (_selectedLead != null) {
        leadIdInt = int.tryParse(_selectedLead!.leadId);
      }

      final project = CustomerProject(
        id: widget.project.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        code: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : null,
        startDate: _startDate,
        endDate: _endDate,
        progress: null, // Removed progress field, pass null so it's omitted in JSON if desired, or null
        // createdBy remains as original - not updated
        projectPhase: _projectPhase ?? 'Planning', // Default to Planning if null
        projectType: _projectType,
        contractType: _contractType,
        state: _state ?? 'Kerala', // Default to Kerala if null

        district: _district ?? 'Thrissur', // Default to Thrissur if null
        sqfeet: _sqfeetController.text.trim().isNotEmpty
            ? double.tryParse(_sqfeetController.text.trim())
            : null,
        leadId: leadIdInt,
        customerId: _selectedCustomer?.id,
        teamMembers: _selectedTeamMembers,
        projectManagerId: _selectedProjectManager?.id != null ? int.tryParse(_selectedProjectManager!.id!) : null,
        latitude: _latitudeController.text.isNotEmpty ? double.tryParse(_latitudeController.text) : null,
        longitude: _longitudeController.text.isNotEmpty ? double.tryParse(_longitudeController.text) : null,
      );


      await _crmService.updateCustomerProject(widget.project.id!, project);

      if (mounted) {
        MotionToast.show(
          context,
          message: 'Project updated successfully!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to update project');
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
        title: const Text('Edit Customer Project'),
      ),
      body: _isPageLoading 
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveContainer(
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

                  // GPS Coordinates Section
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 125),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: AppTheme.coralRed),
                              const SizedBox(width: AppTheme.spacingSM),
                              Text(
                                'GPS Coordinates',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              MotionButton(
                                onPressed: _fetchCurrentLocation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSM,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.coralRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.my_location, size: 14, color: AppTheme.coralRed),
                                      SizedBox(width: 4),
                                      Text(
                                        'Capture',
                                        style: TextStyle(
                                          color: AppTheme.coralRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMD),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude',
                                    hintText: '0.000000',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMD),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude',
                                    hintText: '0.000000',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          Text(
                            'Capture automatically when at site',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
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
                  const SizedBox(height: AppTheme.spacingMD),
                  
                  // Contract Type
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 175),
                    child: DropdownButtonFormField<String>(
                      value: _contractType,
                      decoration: const InputDecoration(
                        labelText: 'Contract Type *',
                        hintText: 'Select contract type',
                      ),
                      items: _contractTypeOptions.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _contractType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a contract type';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),


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

                  EntranceAnimation(
                    delay: const Duration(milliseconds: 250),
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Project Code *',
                        hintText: 'Enter project code',
                        helperText: 'Project code must be unique',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project code is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),


                  const SizedBox(height: AppTheme.spacingMD),

                  EntranceAnimation(
                    delay: const Duration(milliseconds: 300),
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
                                  _district = null;
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
                      delay: const Duration(milliseconds: 350),
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

                  // Project Phase Row (Progress removed)
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: ResponsiveLayout(
                      mobile: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _projectPhase,
                            decoration: const InputDecoration(
                              labelText: 'Project Phase',
                              hintText: 'Select phase',
                            ),
                            items: _projectPhases.map((phase) {
                              return DropdownMenuItem(
                                value: phase,
                                child: Text(phase),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _projectPhase = value;
                              });
                            },
                          ),
                        ],
                      ),
                      desktop: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _projectPhase,
                              decoration: const InputDecoration(
                                labelText: 'Project Phase',
                                hintText: 'Select phase',
                              ),
                              items: _projectPhases.map((phase) {
                                return DropdownMenuItem(
                                  value: phase,
                                  child: Text(phase),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _projectPhase = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),


                  // Lead Selection (Searchable Dropdown)
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead',
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

                  EntranceAnimation(
                    delay: const Duration(milliseconds: 500),
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

                  // Created By (Read-only info)
                  if (widget.project.createdBy != null &&
                      widget.project.createdBy!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: AppTheme.spacingSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created By',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                Text(
                                  widget.project.createdBy!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.project.createdBy != null &&
                      widget.project.createdBy!.isNotEmpty)
                    const SizedBox(height: AppTheme.spacingMD),

                  EntranceAnimation(
                    delay: const Duration(milliseconds: 550),
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
                          onPressed: _isLoading ? null : _saveProject,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update Project'),
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
                        _selectedLeadId = null;
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
            child: _filteredLeads.isEmpty
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
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _selectedLead = lead;
                                  _selectedLeadId = int.tryParse(lead.leadId);
                                  _leadSearchController.text =
                                      '${lead.leadId} - ${lead.name}';
                                  _showLeadDropdown = false;
                                });
                                // Unfocus after a small delay to allow state update
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted) {
                                    _leadSearchFocusNode.unfocus();
                                  }
                                });
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMD),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : Colors.transparent,
                                border: const Border(
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
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lead.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
        if (_selectedLead != null) ...[
          const SizedBox(height: AppTheme.spacingSM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSM),
            decoration: BoxDecoration(
              color: AppTheme.statusSuccessBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: AppTheme.statusSuccess.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppTheme.statusSuccess),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedLead!.leadId} - ${_selectedLead!.name}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.statusSuccess,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedLead = null;
                      _leadSearchController.clear();
                      _filterLeads('');
                      _showLeadDropdown = true;
                      _filteredLeads = _leads;
                    });
                    _leadSearchFocusNode.requestFocus();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
                      ? const Text(
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
                          final isAdmin = member.id != null && _adminIds.contains('${member.type}_${member.id}');
                          final isSelected = isAdmin || _selectedTeamMembers.contains(member);
                          
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
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: Text(
                              member.designation ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            value: isSelected,
                            onChanged: isAdmin ? null : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedTeamMembers.add(member);
                                } else {
                                  _selectedTeamMembers.removeWhere((m) => m.id == member.id);
                                }
                              });
                              // Update parent state as well
                              this.setState(() {}); 
                            },
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

