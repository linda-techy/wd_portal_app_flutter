import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:admin/models/site_visit_models.dart';
import 'package:admin/services/site_visit_service.dart';
import 'package:admin/services/location_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Dialog for site visit check-out with GPS capture.
class SiteVisitCheckOutDialog extends StatefulWidget {
  final SiteVisit activeVisit;

  const SiteVisitCheckOutDialog({super.key, required this.activeVisit});

  /// Show the check-out dialog and return the updated SiteVisit, or null if cancelled.
  static Future<SiteVisit?> show(BuildContext context, SiteVisit activeVisit) {
    return showModalBottomSheet<SiteVisit>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SiteVisitCheckOutDialog(activeVisit: activeVisit),
    );
  }

  @override
  State<SiteVisitCheckOutDialog> createState() => _SiteVisitCheckOutDialogState();
}

class _SiteVisitCheckOutDialogState extends State<SiteVisitCheckOutDialog> {
  final _visitService = SiteVisitService();
  final _notesController = TextEditingController();

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _error;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

  String _calculateDuration() {
    if (widget.activeVisit.checkInTime == null) return '--';
    final duration = DateTime.now().difference(widget.activeVisit.checkInTime!);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Future<void> _submit() async {
    if (_currentPosition == null) {
      setState(() => _error = 'GPS location is required for check-out');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = CheckOutRequest(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final visit = await _visitService.checkOut(widget.activeVisit.id, request);
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
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
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
                        color: AppTheme.coralRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: AppTheme.coralRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Site Visit Check-Out',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            widget.activeVisit.projectName,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                    // Active visit summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.constructionOrange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.constructionOrange.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Active Since',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              Text(
                                widget.activeVisit.checkInTime != null
                                    ? '${widget.activeVisit.checkInTime!.hour.toString().padLeft(2, '0')}:${widget.activeVisit.checkInTime!.minute.toString().padLeft(2, '0')}'
                                    : '--',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.constructionOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _calculateDuration(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.constructionOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.activeVisit.visitType != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Visit Type',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  widget.activeVisit.visitType!,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // GPS Status
                    _buildGpsStatus(),
                    const SizedBox(height: 20),
                    // Check-out notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Check-out Notes (optional)',
                        hintText: 'Summary of work done, observations...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    // Error
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
                            : const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Checking Out...' : 'Check Out',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coralRed,
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
          if (_locationError != null || (_currentPosition == null && !_isLoadingLocation))
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.skyBlue),
              onPressed: _fetchLocation,
              tooltip: 'Retry GPS',
            ),
        ],
      ),
    );
  }
}
