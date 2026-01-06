import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/site_report_models.dart';
import 'dart:convert';

class SiteReportService {
  final ApiService _apiService = ApiService();

  Future<List<SiteReport>> getReportsByProject(int projectId) async {
    try {
      final response = await _apiService.get('/site-reports/project/$projectId');
      return (response.data as List).map((json) => SiteReport.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SiteReport>> getMyReports() async {
    try {
      final response = await _apiService.get('/site-reports/me');
      return (response.data as List).map((json) => SiteReport.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<SiteReport> createReport({
    required int projectId,
    required String title,
    required String description,
    required ReportType reportType,
    int? siteVisitId,
    List<File>? photos,
  }) async {
    try {
      final Map<String, dynamic> reportData = {
        'projectId': projectId,
        'title': title,
        'description': description,
        'reportType': reportType.name,
        'siteVisitId': siteVisitId,
      };

      final formDataMap = {
        'report': MultipartFile.fromString(
          jsonEncode(reportData),
          contentType: DioMediaType.parse('application/json'),
        ),
      };

      if (photos != null && photos.isNotEmpty) {
        formDataMap['photos'] = await Future.wait(
          photos.map((file) async => await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          )),
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _apiService.post(
        '/site-reports',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return SiteReport.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReport(int id) async {
    try {
      await _apiService.delete('/site-reports/$id');
    } catch (e) {
      rethrow;
    }
  }
}
