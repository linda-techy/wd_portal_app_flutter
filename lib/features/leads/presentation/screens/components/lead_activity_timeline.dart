import 'package:flutter/material.dart';
import '../../../data/models/activity_feed.dart';
import '../../../data/services/lead_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class LeadActivityTimeline extends StatefulWidget {
  final String leadId;

  const LeadActivityTimeline({super.key, required this.leadId});

  @override
  State<LeadActivityTimeline> createState() => _LeadActivityTimelineState();
}

class _LeadActivityTimelineState extends State<LeadActivityTimeline> {
  final LeadService _leadService = LeadService();
  List<ActivityFeed> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    // Note: Since this is a component often used inside a screen that already checks auth,
    // we might skip strict redirect here, but for safety we check.
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
       // Parent screen handles redirect usually, but valid to check
       return;
    }
    await _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final activities = await _leadService.getLeadActivities(widget.leadId);
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load activities');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _loadActivities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return const Center(child: Text('No activities recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildTimelineItem(activity, index == _activities.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(ActivityFeed activity, bool isLast) {
    final bool isInteraction = _isInteractionType(activity.activityType);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isInteraction ? Colors.purple : _getColorForType(activity.activityType),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isInteraction ? _getInteractionIcon(activity.activityType) : _getIconForType(activity.activityType),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isInteraction ? Colors.purple.withOpacity(0.3) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Badge to distinguish type
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isInteraction ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isInteraction ? 'INTERACTION' : 'SYSTEM EVENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isInteraction ? Colors.purple.shade700 : Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y HH:mm').format(activity.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(activity.description),
                      if (activity.createdBy != null) ...[
                         const SizedBox(height: 8),
                         Text(
                           'By: ${activity.createdBy}',
                           style: TextStyle(
                             fontStyle: FontStyle.italic,
                             color: Colors.grey.shade600,
                             fontSize: 12,
                           ),
                         ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Check if activity type is an interaction (from lead_interactions table)
  bool _isInteractionType(String activityType) {
    const interactionTypes = ['CALL', 'EMAIL', 'MEETING', 'SITE_VISIT', 'WHATSAPP', 'SMS', 'OTHER'];
    return interactionTypes.contains(activityType.toUpperCase());
  }
  
  // Get icon for interaction types
  IconData _getInteractionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'CALL':
        return Icons.phone;
      case 'EMAIL':
        return Icons.email;
      case 'MEETING':
        return Icons.people;
      case 'SITE_VISIT':
        return Icons.location_on;
      case 'WHATSAPP':
        return Icons.chat;
      case 'SMS':
        return Icons.message;
      default:
        return Icons.chat_bubble;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'LEAD_CREATED':
        return Colors.green;
      case 'LEAD_UPDATED':
        return Colors.blue;
      case 'LEAD_STATUS_CHANGED':
        return Colors.orange;
      case 'LEAD_ASSIGNED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
     switch (type) {
      case 'LEAD_CREATED':
        return Icons.add;
      case 'LEAD_UPDATED':
        return Icons.edit;
      case 'LEAD_STATUS_CHANGED':
        return Icons.swap_horiz;
      case 'LEAD_ASSIGNED':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }
}
