import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/services/portal_notification_service.dart';
import 'package:admin/theme/app_theme.dart';

class PortalNotificationScreen extends StatefulWidget {
  const PortalNotificationScreen({super.key});

  @override
  State<PortalNotificationScreen> createState() => _PortalNotificationScreenState();
}

class _PortalNotificationScreenState extends State<PortalNotificationScreen> {
  PortalNotificationService? _service;
  final List<PortalNotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 20;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _service = PortalNotificationService(Provider.of<ApiService>(context, listen: false));
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _notifications.clear();
        _page = 0;
        _hasMore = true;
      });
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final items = await _service!.getNotifications(page: _page, size: _pageSize);
      setState(() {
        _notifications.addAll(items);
        _hasMore = items.length == _pageSize;
        _page++;
      });
    } catch (_) {
      // Keep existing data on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service!.markAllRead();
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = PortalNotificationModel(
            id: _notifications[i].id,
            title: _notifications[i].title,
            body: _notifications[i].body,
            notificationType: _notifications[i].notificationType,
            projectId: _notifications[i].projectId,
            leadId: _notifications[i].leadId,
            referenceId: _notifications[i].referenceId,
            read: true,
            createdAt: _notifications[i].createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _markRead(PortalNotificationModel notification) async {
    if (notification.read) return;
    try {
      await _service!.markRead(notification.id);
      final idx = _notifications.indexOf(notification);
      if (idx != -1) {
        setState(() {
          _notifications[idx] = PortalNotificationModel(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            notificationType: notification.notificationType,
            projectId: notification.projectId,
            leadId: notification.leadId,
            referenceId: notification.referenceId,
            read: true,
            createdAt: notification.createdAt,
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.any((n) => !n.read))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _notifications.isEmpty && !_isLoading
            ? const _EmptyState()
            : NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  if (scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                    _loadNotifications();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: _notifications.length + (_isLoading ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 64),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final n = _notifications[index];
                    return _NotificationTile(
                      notification: n,
                      onTap: () => _markRead(n),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PortalNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _iconForType(String? type) {
    switch (type) {
      case 'LEAD_NEW':
        return Icons.person_add;
      case 'LEAD_ASSIGNED':
        return Icons.assignment_ind;
      case 'TASK_ASSIGNED':
      case 'TASK_OVERDUE':
        return Icons.task_alt;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppTheme.primaryBlue.withOpacity(0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isUnread
                  ? AppTheme.coralRed
                  : AppTheme.borderLight,
              child: Icon(
                _iconForType(notification.notificationType),
                size: 18,
                color: isUnread ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (notification.body != null &&
                      notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.coralRed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New leads, tasks, and updates will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
