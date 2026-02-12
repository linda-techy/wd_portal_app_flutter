import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/site_report_models.dart';
import '../models/paginated_response.dart';
import 'dart:convert';

class SiteReportService {
  final ApiService _apiService = ApiService();

  Future<List<SiteReport>> getReportsByProject(int projectId) async {
    final response = await _apiService.get('/api/site-reports/project/$projectId');
    return _apiService.unwrapList(
        response, (json) => SiteReport.fromJson(json));
  }

  Future<List<SiteReport>> getMyReports() async {
    final response = await _apiService.get('/api/site-reports/me');
    return _apiService.unwrapList(
        response, (json) => SiteReport.fromJson(json));
  }

  Future<SiteReport> createReport({
    required int projectId,
    required String title,
    required String description,
    required ReportType reportType,
    int? siteVisitId,
    List<XFile>? photos,
  }) async {
    final Map<String, dynamic> reportData = {
      'projectId': projectId,
      'title': title,
      'description': description,
      'reportType': reportType.toJson(),
      'siteVisitId': siteVisitId,
    };

    final formData = FormData();

    // Send report JSON as text/plain so Spring's StringHttpMessageConverter
    // can resolve @RequestPart("report") String correctly.
    // Using application/json causes Spring to try Jackson deserialization
    // into String which fails for JSON objects.
    formData.files.add(MapEntry(
      'report',
      MultipartFile.fromString(
        jsonEncode(reportData),
        contentType: DioMediaType.parse('text/plain'),
      ),
    ));

    if (photos != null && photos.isNotEmpty) {
      for (final file in photos) {
        formData.files.add(MapEntry(
          'photos',
          MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          ),
        ));
      }
    }

    // Don't set contentType explicitly — Dio auto-sets multipart/form-data
    // with the correct boundary when sending FormData
    final response = await _apiService.post(
      '/api/site-reports',
      data: formData,
    );

    return _apiService.unwrap(
        response, (json) => SiteReport.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteReport(int id) async {
    final response = await _apiService.delete('/api/site-reports/$id');
    _apiService.unwrap(response, (_) {});
  }

  /// NEW: Standardized search endpoint for site reports
  Future<PaginatedResponse<SiteReport>> searchSiteReports({
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

    final response = await _apiService.get('/api/site-reports/search',
        queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<SiteReport>>(
      response,
      (json) => PaginatedResponse.fromJson(
          json as Map<String, dynamic>, SiteReport.fromJson),
    );
  }
}
