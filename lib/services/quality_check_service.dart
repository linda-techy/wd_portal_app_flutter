import 'package:admin/services/api_service.dart';
import 'package:admin/models/paginated_response.dart';

class QualityCheck {
  final int? id;
  final int projectId;
  final String title;
  final String description;
  final String status;
  final String? result;
  final String? remarks;
  final DateTime? checkDate;
  final Map<String, dynamic>? conductedBy;

  QualityCheck({
    this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    this.result,
    this.remarks,
    this.checkDate,
    this.conductedBy,
  });

  factory QualityCheck.fromJson(Map<String, dynamic> json) {
    return QualityCheck(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : 0,
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      result: json['result'],
      remarks: json['remarks'],
      checkDate:
          json['checkDate'] != null ? DateTime.parse(json['checkDate']) : null,
      conductedBy: json['conductedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status,
      'result': result,
      'remarks': remarks,
    };
  }

  /// Alias for title (used by quality_checks_screen).
  String get checkType => title;

  /// Project name when provided by API (e.g. from expanded project).
  String? get projectName => null;

  /// Inspector name from conductedBy map when present.
  String? get inspectedByName {
    if (conductedBy == null) return null;
    final name = conductedBy!['name'];
    return name?.toString();
  }

  /// Alias for checkDate (used by quality_checks_screen).
  DateTime? get inspectionDate => checkDate;

  /// Location when provided by API (optional).
  String? get location => null;
}

class QualityCheckService {
  final ApiService _api = ApiService();

  Future<List<QualityCheck>> getProjectChecks(int projectId) async {
    try {
      final response = await _api.dio.get('/api/quality-checks/project/$projectId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => QualityCheck.fromJson(e)).toList();
      }
      throw Exception(
          response.data['message'] ?? 'Failed to load quality checks');
    } catch (e) {
      rethrow;
    }
  }

  Future<QualityCheck> createCheck(QualityCheck check) async {
    try {
      final response = await _api.dio.post(
        '/api/quality-checks',
        data: check.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return QualityCheck.fromJson(response.data['data']);
      }
      throw Exception(
          response.data['message'] ?? 'Failed to create quality check');
    } catch (e) {
      rethrow;
    }
  }

  Future<QualityCheck> updateCheck(int id, QualityCheck check) async {
    try {
      final response = await _api.dio.put(
        '/api/quality-checks/$id',
        data: check.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return QualityCheck.fromJson(response.data['data']);
      }
      throw Exception(
          response.data['message'] ?? 'Failed to update quality check');
    } catch (e) {
      rethrow;
    }
  }

  /// NEW: Standardized search endpoint for quality checks
  Future<PaginatedResponse<QualityCheck>> searchQualityChecks({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response =
        await _api.get('/api/quality-checks/search', queryParams: queryParams);
    return _api.unwrap<PaginatedResponse<QualityCheck>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, QualityCheck.fromJson),
    );
  }
}
