import 'package:admin/services/api_service.dart';

class FeedbackForm {
  final int id;
  final int projectId;
  final String? projectName;
  final String title;
  final String? description;
  final bool isActive;
  final String? createdByName;
  final DateTime? createdAt;
  final int? responseCount;
  final double? averageRating;

  FeedbackForm({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.title,
    this.description,
    required this.isActive,
    this.createdByName,
    this.createdAt,
    this.responseCount,
    this.averageRating,
  });

  factory FeedbackForm.fromJson(Map<String, dynamic> json) {
    return FeedbackForm(
      id: json['id'],
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'],
      title: json['title'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdByName: json['createdByName'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      responseCount: json['responseCount'],
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
    );
  }
}

class FeedbackResponse {
  final int id;
  final int formId;
  final String? formTitle;
  final int? customerId;
  final String? customerName;
  final String? responseData;
  final DateTime? submittedAt;

  FeedbackResponse({
    required this.id,
    required this.formId,
    this.formTitle,
    this.customerId,
    this.customerName,
    this.responseData,
    this.submittedAt,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      id: json['id'],
      formId: json['formId'] ?? 0,
      formTitle: json['formTitle'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      responseData: json['responseData'],
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }
}

class FeedbackService {
  final ApiService _api = ApiService();

  Future<List<FeedbackForm>> getProjectForms(int projectId, {bool activeOnly = false}) async {
    final response = await _api.dio.get(
      '/api/feedback/forms/project/$projectId',
      queryParameters: {'activeOnly': activeOnly},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((e) => FeedbackForm.fromJson(e)).toList();
    }
    throw Exception('Failed to load feedback forms');
  }

  Future<FeedbackForm> createForm({
    required int projectId,
    required String title,
    String? description,
  }) async {
    final response = await _api.dio.post('/api/feedback/forms', data: {
      'projectId': projectId,
      'title': title,
      'description': description,
    });
    if (response.statusCode == 200) {
      return FeedbackForm.fromJson(response.data);
    }
    throw Exception('Failed to create feedback form');
  }

  Future<FeedbackForm> updateForm(int formId, {
    String? title,
    String? description,
    bool? isActive,
  }) async {
    final response = await _api.dio.put('/api/feedback/forms/$formId', data: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
    });
    if (response.statusCode == 200) {
      return FeedbackForm.fromJson(response.data);
    }
    throw Exception('Failed to update feedback form');
  }

  Future<void> deleteForm(int formId) async {
    final response = await _api.dio.delete('/api/feedback/forms/$formId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete feedback form');
    }
  }

  Future<List<FeedbackResponse>> getFormResponses(int formId) async {
    final response = await _api.dio.get('/api/feedback/forms/$formId/responses');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((e) => FeedbackResponse.fromJson(e)).toList();
    }
    throw Exception('Failed to load feedback responses');
  }

  Future<List<FeedbackResponse>> getProjectResponses(int projectId) async {
    final response = await _api.dio.get('/api/feedback/responses/project/$projectId');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((e) => FeedbackResponse.fromJson(e)).toList();
    }
    throw Exception('Failed to load feedback responses');
  }
}
