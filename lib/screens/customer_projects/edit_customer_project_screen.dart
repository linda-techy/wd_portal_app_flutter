import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import '../../models/lead.dart';
import '../../services/crm_service.dart';
import '../../utils/india_location_data.dart';

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
  late final TextEditingController _progressController;
  late final TextEditingController _leadSearchController;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _projectPhase;
  String? _state;
  String? _district;
  int? _selectedLeadId;
  Lead? _selectedLead;
  List<Lead> _leads = [];
  List<Lead> _filteredLeads = [];
  bool _isLoadingLeads = false;
  bool _isLoading = false;
  bool _showLeadDropdown = false;
  final FocusNode _leadSearchFocusNode = FocusNode();

  final List<String> _projectPhases = [
    'Planning',
    'Design',
    'Foundation',
    'Construction',
    'Finishing',
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
    _progressController = TextEditingController(
      text: widget.project.progress != null
          ? widget.project.progress!.toStringAsFixed(1)
          : '',
    );
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

    _loadLeads();

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
  }

  Future<void> _loadLeads() async {
    try {
      setState(() => _isLoadingLeads = true);
      final leads = await _crmService.getAllLeads();
      if (mounted) {
        setState(() {
          _leads = leads;
          _filteredLeads = leads;
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
          _isLoadingLeads = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLeads = false);
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
    _progressController.dispose();
    _leadSearchController.dispose();
    _leadSearchFocusNode.dispose();
    super.dispose();
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
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          if (_startDate == null || picked.isAfter(_startDate!)) {
            _endDate = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date must be after start date'),
                backgroundColor: AppTheme.statusError,
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.project.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid project ID'),
          backgroundColor: AppTheme.statusError,
        ),
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
        progress: _progressController.text.trim().isNotEmpty
            ? double.tryParse(_progressController.text.trim())
            : widget.project.progress ?? 0.0, // Default to existing or 0.0
        // createdBy remains as original - not updated
        projectPhase: _projectPhase ?? 'Planning', // Default to Planning if null
        state: _state ?? 'Kerala', // Default to Kerala if null
        district: _district ?? 'Thrissur', // Default to Thrissur if null
        sqfeet: _sqfeetController.text.trim().isNotEmpty
            ? double.tryParse(_sqfeetController.text.trim())
            : null,
        leadId: leadIdInt,
      );

      await _crmService.updateCustomerProject(widget.project.id!, project);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update project: ${e.toString()}'),
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
        title: const Text('Edit Customer Project'),
      ),
      body: AdaptiveContainer(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Information',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingLG),

                  // Name
                  TextFormField(
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
                  const SizedBox(height: AppTheme.spacingMD),

                  // Code (Editable in edit screen)
                  TextFormField(
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
                  const SizedBox(height: AppTheme.spacingMD),

                  // Location
                  TextFormField(
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
                  const SizedBox(height: AppTheme.spacingMD),

                  // State and District Row
                  ResponsiveLayout(
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
                  const SizedBox(height: AppTheme.spacingMD),

                  // Start Date and End Date Row
                  ResponsiveLayout(
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
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(_endDate!)
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
                  const SizedBox(height: AppTheme.spacingMD),

                  // Project Phase and Progress Row
                  ResponsiveLayout(
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
                        const SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _progressController,
                          decoration: const InputDecoration(
                            labelText: 'Progress (%)',
                            hintText: '0-100',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final progress = double.tryParse(value);
                              if (progress == null ||
                                  progress < 0 ||
                                  progress > 100) {
                                return 'Progress must be between 0 and 100';
                              }
                            }
                            return null;
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
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: TextFormField(
                            controller: _progressController,
                            decoration: const InputDecoration(
                              labelText: 'Progress (%)',
                              hintText: '0-100',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final progress = double.tryParse(value);
                                if (progress == null ||
                                    progress < 0 ||
                                    progress > 100) {
                                  return 'Progress must be between 0 and 100';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),

                  // Lead Selection (Searchable Dropdown)
                  Column(
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
                          Icon(Icons.person,
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

                  // Sq Feet
                  TextFormField(
                    controller: _sqfeetController,
                    decoration: const InputDecoration(
                      labelText: 'Square Feet',
                      hintText: 'Enter area in sqft',
                    ),
                    keyboardType: TextInputType.number,
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
                    ],
                  ),
              ],
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
                                    Icon(
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
                Icon(Icons.check_circle,
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
                      _selectedLeadId = null;
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
}
