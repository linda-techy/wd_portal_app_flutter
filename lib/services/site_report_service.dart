import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/site_report_models.dart';
import '../models/paginated_response.dart';
import 'dart:convert';

class SiteReportService {
  final ApiService _apiService = ApiService();

  Future<List<SiteReport>> getReportsByProject(int projectId) async {
    final response = await _apiService.get('/site-reports/project/$projectId');
    return _apiService.unwrapList(
        response, (json) => SiteReport.fromJson(json));
  }

  Future<List<SiteReport>> getMyReports() async {
    final response = await _apiService.get('/site-reports/me');
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
      'reportType': reportType.name,
      'siteVisitId': siteVisitId,
    };

    final Map<String, dynamic> formDataMap = {
      'report': MultipartFile.fromString(
        jsonEncode(reportData),
        contentType: DioMediaType.parse('application/json'),
      ),
    };

    if (photos != null && photos.isNotEmpty) {
      formDataMap['photos'] = await Future.wait(
        photos.map((file) async => MultipartFile.fromBytes(
              await file.readAsBytes(),
              filename: file.name,
            )),
      );
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _apiService.post(
      '/site-reports',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return _apiService.unwrap(
        response, (json) => SiteReport.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteReport(int id) async {
    final response = await _apiService.delete('/site-reports/$id');
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
