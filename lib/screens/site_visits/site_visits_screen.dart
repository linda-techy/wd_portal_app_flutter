import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:admin/constants.dart';
import 'package:admin/services/site_visit_service.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/models/site_visit_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../reports/add_site_report_screen.dart';
import '../../theme/app_theme.dart';

class SiteVisitsScreen extends StatefulWidget {
  const SiteVisitsScreen({super.key});

  @override
  _SiteVisitsScreenState createState() => _SiteVisitsScreenState();
}

class _SiteVisitsScreenState extends State<SiteVisitsScreen> {
  final SiteVisitService _siteVisitService = SiteVisitService();
  final CRMService _crmService = CRMService();
  
  SiteVisit? _activeVisit;
  List<CustomerProject> _projects = [];
  List<VisitTypeOption> _visitTypes = [];
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeVisit = await _siteVisitService.getMyActiveVisit();
      final projects = await _crmService.getAllCustomerProjects();
      final visitTypes = await _siteVisitService.getVisitTypes();
      
      setState(() {
        _activeVisit = activeVisit;
        _projects = projects;
        _visitTypes = visitTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _handleCheckIn(int projectId, String visitType, String? notes) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _getCurrentLocation();

      final request = CheckInRequest(
        projectId: projectId,
        latitude: position.latitude,
        longitude: position.longitude,
        visitType: visitType,
        notes: notes ?? 'Checked in via mobile app',
      );

      final visit = await _siteVisitService.checkIn(request);

      setState(() {
        _activeVisit = visit;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked in'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckOut(String notes) async {
    if (_activeVisit == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _getCurrentLocation();

      final request = CheckOutRequest(
        latitude: position.latitude,
        longitude: position.longitude,
        notes: notes,
      );

      await _siteVisitService.checkOut(_activeVisit!.id, request);

      setState(() {
        _activeVisit = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked out'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCheckInDialog() async {
    int? selectedProjectId;
    String? selectedVisitType;
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (_projects.isEmpty || _visitTypes.isEmpty) {
      await _loadInitialData();
    }

    if (mounted) {
      final confirmed = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Check In'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select project and visit type to start tracking.'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Project',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedProjectId,
                      items: _projects.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.projectName),
                      )).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) => setDialogState(() => selectedProjectId = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Visit Type',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedVisitType,
                      items: _visitTypes.map((t) => DropdownMenuItem(
                        value: t.value,
                        child: Text(t.label),
                      )).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (v) => setDialogState(() => selectedVisitType = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Check-in Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'projectId': selectedProjectId,
                      'visitType': selectedVisitType,
                      'notes': notesController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed, foregroundColor: Colors.white),
                child: const Text('Check In'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != null) {
        await _handleCheckIn(
          confirmed['projectId'] as int,
          confirmed['visitType'] as String,
          confirmed['notes'] as String?,
        );
      }
    }
  }

  void _showCheckOutDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add any notes about today\'s work:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Work completed, issues encountered, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );

    if (confirmed != null) {
      await _handleCheckOut(confirmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Site Visits"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _loadInitialData,
           ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.coralRed))
                  : _activeVisit != null
                      ? _buildActiveVisitCard()
                      : _buildCheckInPrompt(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveVisitCard() {
    final duration = _activeVisit!.checkInTime != null
        ? DateTime.now().difference(_activeVisit!.checkInTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'CHECKED IN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${duration.inHours}h ${duration.inMinutes % 60}m',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _activeVisit!.projectName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Check-in: ${DateFormat('hh:mm a').format(_activeVisit!.checkInTime!)}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.category_outlined, 'Type: ${_activeVisit!.visitType ?? "N/A"}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'GPS: ${_activeVisit!.checkInLatitude?.toStringAsFixed(6)}, ${_activeVisit!.checkInLongitude?.toStringAsFixed(6)}'),
          if (_activeVisit!.notes != null && _activeVisit!.notes!.isNotEmpty) ...[
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: Colors.grey.shade50,
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                 _activeVisit!.notes!,
                 style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
               ),
             ),
          ],
          const Spacer(),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final project = _projects.firstWhere(
                      (p) => p.id == _activeVisit!.projectId,
                      orElse: () => CustomerProject(
                        id: _activeVisit!.projectId,
                        name: _activeVisit!.projectName,
                        location: '',
                        sqfeet: 0,
                        projectPhase: '',
                        startDate: DateTime.now(),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSiteReportScreen(
                          initialProject: project,
                          siteVisitId: _activeVisit!.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Create Site Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCheckOutDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('Check Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      ],
    );
  }

  Widget _buildCheckInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.coralRed.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, size: 80, color: AppTheme.coralRed),
          ),
          const SizedBox(height: 30),
          const Text(
            "Ready to Start?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Check in to a site to track your visit, log notes, and create site reports.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 250,
            child: ElevatedButton.icon(
              onPressed: _showCheckInDialog,
              icon: const Icon(Icons.login),
              label: const Text('Check In to Site'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
                shadowColor: AppTheme.coralRed.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
