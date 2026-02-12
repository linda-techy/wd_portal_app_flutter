import 'package:dio/dio.dart' show FormData;
import 'package:admin/services/api_service.dart';

class ObservationItem {
  final int id;
  final int projectId;
  final String title;
  final String description;
  final String? location;
  final String? priority;
  final String status;
  final String? imagePath;
  final String? reportedByName;
  final String? resolvedByName;
  final DateTime? resolvedDate;
  final String? resolutionNotes;
  final DateTime createdAt;

  ObservationItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.location,
    this.priority,
    required this.status,
    this.imagePath,
    this.reportedByName,
    this.resolvedByName,
    this.resolvedDate,
    this.resolutionNotes,
    required this.createdAt,
  });

  factory ObservationItem.fromJson(Map<String, dynamic> json) {
    return ObservationItem(
      id: json['id'],
      projectId: json['projectId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      priority: json['priority'],
      status: json['status'] ?? 'OPEN',
      imagePath: json['imagePath'],
      reportedByName: json['reportedByName'],
      resolvedByName: json['resolvedByName'],
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.tryParse(json['resolvedDate'].toString())
          : null,
      resolutionNotes: json['resolutionNotes'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isActive =>
      status.toUpperCase() != 'RESOLVED' && status.toUpperCase() != 'CLOSED';
}

class ObservationService {
  final ApiService _api = ApiService();

  Future<List<ObservationItem>> getActiveObservations(int projectId) async {
    final response =
        await _api.dio.get('/api/observations/project/$projectId/active');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => ObservationItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load active observations');
  }

  Future<List<ObservationItem>> getResolvedObservations(int projectId) async {
    final response =
        await _api.dio.get('/api/observations/project/$projectId/resolved');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => ObservationItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load resolved observations');
  }

  Future<Map<String, int>> getCounts(int projectId) async {
    final response =
        await _api.dio.get('/api/observations/project/$projectId/counts');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    return {'active': 0, 'resolved': 0, 'total': 0};
  }

  Future<ObservationItem> createObservation({
    required int projectId,
    required String title,
    required String description,
    String? location,
    String? priority,
  }) async {
    final formData = {
      'title': title,
      'description': description,
      if (location != null) 'location': location,
      if (priority != null) 'priority': priority,
    };

    // Use FormData for multipart/form-data
    final response = await _api.dio.post(
      '/api/observations/project/$projectId',
      data: FormData.fromMap(formData),
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ObservationItem.fromJson(response.data['data']);
    }
    throw Exception(
        response.data['message'] ?? 'Failed to create observation');
  }

  Future<ObservationItem> resolveObservation(
      int id, String? resolutionNotes) async {
    final response = await _api.dio.post(
      '/api/observations/$id/resolve',
      queryParameters: {
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      },
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ObservationItem.fromJson(response.data['data']);
    }
    throw Exception(
        response.data['message'] ?? 'Failed to resolve observation');
  }

  Future<void> deleteObservation(int id) async {
    final response = await _api.dio.delete('/api/observations/$id');
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(
          response.data['message'] ?? 'Failed to delete observation');
    }
  }
}

