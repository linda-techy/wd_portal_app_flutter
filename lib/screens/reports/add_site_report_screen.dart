import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/site_report_models.dart';
import '../../models/customer_project.dart';
import '../../services/site_report_service.dart';
import '../../services/crm_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../constants.dart';

class AddSiteReportScreen extends StatefulWidget {
  final CustomerProject? initialProject;
  final int? siteVisitId;

  const AddSiteReportScreen({
    super.key,
    this.initialProject,
    this.siteVisitId,
  });

  @override
  State<AddSiteReportScreen> createState() => _AddSiteReportScreenState();
}

class _AddSiteReportScreenState extends State<AddSiteReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _siteReportService = SiteReportService();
  final _imagePicker = ImagePicker();

  CustomerProject? _selectedProject;
  List<CustomerProject> _projects = [];
  ReportType _selectedType = ReportType.dailyProgress;
  final List<XFile> _photos = [];
  bool _isSaving = false;

  // GPS/Location state
  double? _latitude;
  double? _longitude;
  double? _locationAccuracy;
  bool _isLoadingLocation = false;
  bool _locationCaptured = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _selectedProject = widget.initialProject;
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await CRMService().getAllCustomerProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
        });
      }
    } catch (e) {
      if (mounted) {
        MotionToast.error(description: Text('Error loading projects: $e'))
            .show(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFiles = source == ImageSource.camera
          ? [await _imagePicker.pickImage(imageQuality: 70, source: source)]
          : await _imagePicker.pickMultiImage(imageQuality: 70);

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final pickedFile in pickedFiles) {
            if (pickedFile != null) {
              _photos.add(pickedFile);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        MotionToast.error(description: Text('Error picking image: $e'))
            .show(context);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final Position position = await LocationService.getCurrentPosition();
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationAccuracy = position.accuracy;
        _locationCaptured = true;
        _isLoadingLocation = false;
      });

      if (mounted) {
        MotionToast.success(
          description: const Text('Location captured successfully'),
          toastDuration: const Duration(seconds: 2),
        ).show(context);
      }
    } on LocationException catch (e) {
      setState(() {
        _locationError = e.message;
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        MotionToast.error(
          description: Text(e.message),
          toastDuration: const Duration(seconds: 4),
        ).show(context);
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to capture location: $e';
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        MotionToast.error(
          description: Text('Failed to capture location: $e'),
        ).show(context);
      }
    }
  }

  Future<void> _saveReport() async {
    if (_selectedProject == null) {
      MotionToast.warning(description: const Text('Please select a project'))
          .show(context);
      return;
    }

    if (_selectedProject!.id == null) {
      MotionToast.error(description: const Text('Invalid project selected'))
          .show(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Validate photo is required
    if (_photos.isEmpty) {
      MotionToast.warning(
        description: const Text('At least one photo is required'),
        toastDuration: const Duration(seconds: 3),
      ).show(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _siteReportService.createReport(
        projectId: _selectedProject!.id!,
        title: _titleController.text,
        description: _descriptionController.text,
        reportType: _selectedType,
        siteVisitId: widget.siteVisitId,
        photos: _photos,
        latitude: _latitude,
        longitude: _longitude,
        locationAccuracy: _locationAccuracy,
      );

      if (mounted) {
        MotionToast.success(
                description: const Text('Report submitted successfully'))
            .show(context);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        MotionToast.error(description: Text('Error submitting report: $e'))
            .show(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Site Report'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.coralRed),
              ),
            )
          else
            TextButton(
              onPressed: _saveReport,
              child: const Text('SUBMIT',
                  style: TextStyle(
                      color: AppTheme.coralRed, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectSelector(),
              const SizedBox(height: defaultPadding),
              _buildReportTypeSelector(),
              const SizedBox(height: defaultPadding),
              _buildTextField(
                  'Title', _titleController, 'e.g., Progress on Foundation'),
              const SizedBox(height: defaultPadding),
              _buildTextField('Description', _descriptionController,
                  'Detail the observations...',
                  maxLines: 5),
              const SizedBox(height: defaultPadding * 1.5),
              _buildLocationSection(),
              const SizedBox(height: defaultPadding * 1.5),
              _buildPhotoSection(),
              const SizedBox(height: defaultPadding * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<CustomerProject>(
          value: _selectedProject,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _projects
              .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.projectName)))
              .toList(),
          onChanged: widget.initialProject != null
              ? null
              : (val) => setState(() => _selectedProject = val),
          validator: (val) => val == null ? 'Project is required' : null,
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Report Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ReportType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
              selectedColor: AppTheme.coralRed.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.coralRed : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) =>
              val == null || val.isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('Photos',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 4),
                Text('*',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: AppTheme.coralRed),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.photo_library, color: AppTheme.coralRed),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
        if (_photos.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.red.shade300,
                  width: 2,
                  style: BorderStyle.solid),
            ),
            child: const Center(
              child: Text(
                'Please add at least one photo (Required)',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_photos[index].path,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.coralRed, size: 20),
            SizedBox(width: 8),
            Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 8),
            Text('(Recommended)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        if (!_locationCaptured && !_isLoadingLocation)
          ElevatedButton.icon(
            onPressed: _captureLocation,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Capture Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else if (_isLoadingLocation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Capturing location...', style: TextStyle(color: Colors.blue)),
              ],
            ),
          )
        else if (_locationCaptured)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Location Captured Successfully',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_latitude?.toStringAsFixed(6)}, Lng: ${_longitude?.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                if (_locationAccuracy != null)
                  Text(
                    'Accuracy: ±${_locationAccuracy!.toStringAsFixed(1)}m',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _captureLocation,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Recapture'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.coralRed,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        if (_locationError != null && !_isLoadingLocation && !_locationCaptured)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
