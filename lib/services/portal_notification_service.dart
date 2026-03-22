import 'package:admin/services/api_service.dart';
import 'package:dio/dio.dart';

class PortalNotificationModel {
  final int id;
  final String title;
  final String? body;
  final String? notificationType;
  final int? projectId;
  final int? leadId;
  final int? referenceId;
  final bool read;
  final DateTime createdAt;

  PortalNotificationModel({
    required this.id,
    required this.title,
    this.body,
    this.notificationType,
    this.projectId,
    this.leadId,
    this.referenceId,
    required this.read,
    required this.createdAt,
  });

  factory PortalNotificationModel.fromJson(Map<String, dynamic> json) {
    return PortalNotificationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      notificationType: json['notificationType'] as String?,
      projectId: json['projectId'] as int?,
      leadId: json['leadId'] as int?,
      referenceId: json['referenceId'] as int?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PortalNotificationService {
  final Dio _dio;

  PortalNotificationService(ApiService apiService) : _dio = apiService.dio;

  Future<List<PortalNotificationModel>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/portal/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    final List<dynamic> content = response.data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => PortalNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/api/portal/notifications/unread-count');
    return response.data['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.put('/api/portal/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.put('/api/portal/notifications/read-all');
  }
}
