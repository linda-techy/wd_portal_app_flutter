import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/site_visit_models.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/services/site_visit_service.dart';
import 'package:admin/services/location_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Dialog for site visit check-in with GPS capture and project selection.
class SiteVisitCheckInDialog extends StatefulWidget {
  const SiteVisitCheckInDialog({super.key});

  /// Show the check-in dialog and return the created SiteVisit, or null if cancelled.
  static Future<SiteVisit?> show(BuildContext context) {
    return showModalBottomSheet<SiteVisit>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SiteVisitCheckInDialog(),
    );
  }

  @override
  State<SiteVisitCheckInDialog> createState() => _SiteVisitCheckInDialogState();
}

class _SiteVisitCheckInDialogState extends State<SiteVisitCheckInDialog> {
  final _projectService = CustomerProjectService();
  final _visitService = SiteVisitService();
  final _notesController = TextEditingController();

  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  String _selectedVisitType = 'GENERAL';
  Position? _currentPosition;
  bool _isLoadingProjects = true;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _error;
  String? _locationError;

  static const _visitTypes = {
    'SITE_ENGINEER': 'Site Engineer',
    'PROJECT_MANAGER': 'Project Manager',
    'SUPERVISOR': 'Supervisor',
    'CONTRACTOR': 'Contractor',
    'CLIENT': 'Client',
    'GENERAL': 'General',
  };

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _fetchLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final response = await _projectService.getProjects(size: 100);
      if (mounted) {
        setState(() {
          _projects = response.content;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load projects: $e';
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    try {
      final position = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedProject == null) {
      setState(() => _error = 'Please select a project');
      return;
    }
    if (_currentPosition == null) {
      setState(() => _error = 'GPS location is required for check-in');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = CheckInRequest(
        projectId: _selectedProject!.id!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        visitType: _selectedVisitType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final visit = await _visitService.checkIn(request);
      if (mounted) {
        Navigator.of(context).pop(visit);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.login, color: AppTheme.successGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site Visit Check-In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'GPS verification required within 200 m of site',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // GPS Status
                    _buildGpsStatus(),
                    const SizedBox(height: 20),
                    // Project Selection
                    _buildProjectDropdown(),
                    const SizedBox(height: 16),
                    // Visit Type
                    _buildVisitTypeDropdown(),
                    const SizedBox(height: 16),
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any check-in notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (_isSubmitting || _currentPosition == null)
                            ? null
                            : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Checking In...' : 'Check In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGpsStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _currentPosition != null
            ? AppTheme.successGreen.withOpacity(0.05)
            : _locationError != null
                ? AppTheme.errorRed.withOpacity(0.05)
                : AppTheme.skyBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentPosition != null
              ? AppTheme.successGreen.withOpacity(0.3)
              : _locationError != null
                  ? AppTheme.errorRed.withOpacity(0.3)
                  : AppTheme.skyBlue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _currentPosition != null
                ? Icons.gps_fixed
                : _locationError != null
                    ? Icons.gps_off
                    : Icons.gps_not_fixed,
            color: _currentPosition != null
                ? AppTheme.successGreen
                : _locationError != null
                    ? AppTheme.errorRed
                    : AppTheme.skyBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingLocation
                      ? 'Acquiring GPS location...'
                      : _currentPosition != null
                          ? 'GPS Location Acquired'
                          : 'GPS Location Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _currentPosition != null
                        ? AppTheme.successGreen
                        : _locationError != null
                            ? AppTheme.errorRed
                            : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (_isLoadingLocation)
                  const LinearProgressIndicator()
                else if (_currentPosition != null)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.textSecondary,
                    ),
                  )
                else if (_locationError != null)
                  Text(
                    _locationError!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
                  ),
              ],
            ),
          ),
          if (_locationError != null || _currentPosition == null && !_isLoadingLocation)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.skyBlue),
              onPressed: _fetchLocation,
              tooltip: 'Retry GPS',
            ),
        ],
      ),
    );
  }

  Widget _buildProjectDropdown() {
    if (_isLoadingProjects) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<CustomerProject>(
      value: _selectedProject,
      decoration: InputDecoration(
        labelText: 'Select Project *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.business),
      ),
      items: _projects.map((project) {
        final hasGps = project.latitude != null && project.longitude != null;
        return DropdownMenuItem(
          value: project,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasGps)
                const Icon(Icons.gps_fixed, size: 14, color: AppTheme.successGreen)
              else
                const Icon(Icons.gps_off, size: 14, color: AppTheme.textTertiary),
            ],
          ),
        );
      }).toList(),
      onChanged: (project) => setState(() {
        _selectedProject = project;
        _error = null;
      }),
      isExpanded: true,
    );
  }

  Widget _buildVisitTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVisitType,
      decoration: InputDecoration(
        labelText: 'Visit Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.category),
      ),
      items: _visitTypes.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) setState(() => _selectedVisitType = type);
      },
    );
  }
}
