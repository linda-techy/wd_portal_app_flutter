import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/customer_project_provider.dart';
import 'package:admin/providers/common_data_provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/enum_value.dart';
import 'package:intl/intl.dart';

class ProjectFormDialog extends StatefulWidget {
  final int? projectId; // null for create, non-null for edit

  const ProjectFormDialog({super.key, this.projectId});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _sqfeetController = TextEditingController();
  final _plotAreaController = TextEditingController();
  final _floorsController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form values
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPhase;
  String? _selectedType;
  String? _selectedContractType;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedFacing;
  String? _selectedDesignPackage;
  bool _isDesignAgreementSigned = false;
  int? _selectedCustomerId;
  int? _selectedProjectManagerId;
  
  bool _isLoading = false;
  bool _isLoadingProject = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
      if (widget.projectId != null) {
        _loadProject();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sqfeetController.dispose();
    _plotAreaController.dispose();
    _floorsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    final commonDataProvider = context.read<CommonDataProvider>();
    await commonDataProvider.loadAll();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoadingProject = true);
    
    try {
      final projectProvider = context.read<CustomerProjectProvider>();
      await projectProvider.fetchProjectById(widget.projectId!);
      
      final project = projectProvider.selectedProject;
      if (project != null && mounted) {
        setState(() {
          _nameController.text = project.name;
          _locationController.text = project.location;
          _sqfeetController.text = project.sqfeet?.toString() ?? '';
          _plotAreaController.text = project.plotArea?.toString() ?? '';
          _floorsController.text = project.floors?.toString() ?? '';
          _latitudeController.text = project.latitude?.toString() ?? '';
          _longitudeController.text = project.longitude?.toString() ?? '';
          _descriptionController.text = project.projectDescription ?? '';
          
          _startDate = project.startDate;
          _endDate = project.endDate;
          _selectedPhase = project.projectPhase;
          _selectedType = project.projectType;
          _selectedContractType = project.contractType;
          _selectedState = project.state;
          _selectedDistrict = project.district;
          _selectedFacing = project.facing;
          _selectedDesignPackage = project.designPackage;
          _isDesignAgreementSigned = project.isDesignAgreementSigned;
          _selectedCustomerId = project.customerId;
          _selectedProjectManagerId = project.projectManagerId;
        });
        
        // Load districts for selected state
        if (_selectedState != null) {
          final commonDataProvider = context.read<CommonDataProvider>();
          await commonDataProvider.fetchDistricts(_selectedState!);
        }
      }
    } finally {
      setState(() => _isLoadingProject = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _onStateChanged(String? state) async {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null; // Reset district when state changes
    });
    
    if (state != null) {
      final commonDataProvider = context.read<CommonDataProvider>();
      await commonDataProvider.fetchDistricts(state);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final project = CustomerProject(
        id: widget.projectId,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        projectPhase: _selectedPhase,
        projectType: _selectedType,
        contractType: _selectedContractType,
        state: _selectedState,
        district: _selectedDistrict,
        sqfeet: _sqfeetController.text.isNotEmpty
            ? double.tryParse(_sqfeetController.text)
            : null,
        plotArea: _plotAreaController.text.isNotEmpty
            ? double.tryParse(_plotAreaController.text)
            : null,
        floors: _floorsController.text.isNotEmpty
            ? int.tryParse(_floorsController.text)
            : null,
        facing: _selectedFacing,
        latitude: _latitudeController.text.isNotEmpty
            ? double.tryParse(_latitudeController.text)
            : null,
        longitude: _longitudeController.text.isNotEmpty
            ? double.tryParse(_longitudeController.text)
            : null,
        designPackage: _selectedDesignPackage,
        isDesignAgreementSigned: _isDesignAgreementSigned,
        customerId: _selectedCustomerId,
        projectManagerId: _selectedProjectManagerId,
        projectDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      final projectProvider = context.read<CustomerProjectProvider>();
      final bool success;

      if (widget.projectId == null) {
        // Create
        success = await projectProvider.createProject(project);
      } else {
        // Update
        success = await projectProvider.updateProject(widget.projectId!, project);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.projectId == null
                  ? 'Project created successfully'
                  : 'Project updated successfully'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(projectProvider.error ?? 'Failed to save project'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.projectId == null ? 'Create New Project' : 'Edit Project',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: _isLoadingProject
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfoSection(),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildTimelineSection(),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildClassificationSection(),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildLocationSection(),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildDimensionsSection(),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildAgreementSection(),
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.projectId == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Project Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Project name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMD),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Timeline'),
        const SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select date',
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
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                        : 'Select date',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassificationSection() {
    return Consumer<CommonDataProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Classification'),
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<String>(
              value: _selectedPhase,
              decoration: const InputDecoration(
                labelText: 'Project Phase *',
                border: OutlineInputBorder(),
              ),
              items: provider.projectPhases.map((EnumValue phase) {
                return DropdownMenuItem<String>(
                  value: phase.value,
                  child: Text(phase.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPhase = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Project phase is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Project Type *',
                border: OutlineInputBorder(),
              ),
              items: provider.projectTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Project type is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<String>(
              value: _selectedContractType,
              decoration: const InputDecoration(
                labelText: 'Contract Type *',
                border: OutlineInputBorder(),
              ),
              items: provider.contractTypes.map((EnumValue type) {
                return DropdownMenuItem<String>(
                  value: type.value,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedContractType = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Contract type is required';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return Consumer<CommonDataProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Location Details'),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.states.map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: _onStateChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'District *',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.getDistricts(_selectedState ?? '').map((String district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedDistrict = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'District is required';
                      }
                      return null;
                    },
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
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDimensionsSection() {
    return Consumer<CommonDataProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Dimensions'),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sqfeetController,
                    decoration: const InputDecoration(
                      labelText: 'Sq Feet',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: TextFormField(
                    controller: _plotAreaController,
                    decoration: const InputDecoration(
                      labelText: 'Plot Area',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _floorsController,
                    decoration: const InputDecoration(
                      labelText: 'Floors',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFacing,
                    decoration: const InputDecoration(
                      labelText: 'Facing',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.facingOptions.map((String facing) {
                      return DropdownMenuItem<String>(
                        value: facing,
                        child: Text(facing),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedFacing = value),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgreementSection() {
    return Consumer<CommonDataProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Agreement'),
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<String>(
              value: _selectedDesignPackage,
              decoration: const InputDecoration(
                labelText: 'Design Package',
                border: OutlineInputBorder(),
              ),
              items: provider.designPackages.map((String package) {
                return DropdownMenuItem<String>(
                  value: package,
                  child: Text(package),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDesignPackage = value),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            CheckboxListTile(
              title: const Text('Design Agreement Signed'),
              value: _isDesignAgreementSigned,
              onChanged: (value) {
                setState(() => _isDesignAgreementSigned = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }
}

