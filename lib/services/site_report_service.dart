import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local/outbox_mutation_type.dart';
import '../data/local/photo_capture.dart';
import '../models/site_report_models.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';
import 'outbox_service.dart';
import 'sync_service.dart';

/// PR2 contract: [SiteReportService.createReportQueued] returns
/// [SiteReportResult]. The pre-PR2 synchronous `Future<SiteReport>` shape on
/// the legacy [createReport] now throws — call sites must migrate to the
/// queued variant and treat the report as in-flight until the outbox drains.
sealed class SiteReportResult {
  const SiteReportResult();
}

class SiteReportResultQueued extends SiteReportResult {
  const SiteReportResultQueued(this.outboxEntryId);
  final int outboxEntryId;
}

class SiteReportService {
  SiteReportService()
      : _outbox = null,
        _sync = null;

  /// PR2 binding for the site-engineer flow. Required by [createReportQueued].
  SiteReportService.forOutbox({
    required OutboxService outbox,
    required SyncService sync,
  })  : _outbox = outbox,
        _sync = sync;

  final ApiService _apiService = ApiService();
  final OutboxService? _outbox;
  final SyncService? _sync;

  /// Reports for a single project, ordered newest first.
  Future<List<SiteReport>> getReportsByProject(int projectId) async {
    final page = await searchSiteReports(
      page: 0,
      size: 200,
      sortBy: 'reportDate',
      sortDirection: 'desc',
      filters: {'projectId': projectId},
    );
    return page.content;
  }

  Future<List<SiteReport>> getMyReports() async {
    final response = await _apiService.get('/api/site-reports/me');
    return _apiService.unwrapList(
        response, (json) => SiteReport.fromJson(json));
  }

  /// PR2 entry point. Persists the report to the outbox + queues the photo
  /// for upload. Returns immediately with [SiteReportResultQueued]. The
  /// [SyncService] later dispatches the multipart POST when online.
  ///
  /// S5 keeps a single photo per outbox row; multi-photo reports are out of
  /// scope for PR2 (deferred — one outbox row per photo + a server-side merge
  /// endpoint).
  Future<SiteReportResult> createReportQueued({
    required int projectId,
    required String title,
    required String description,
    required ReportType reportType,
    int? siteVisitId,
    int? taskId,
    PhotoCapture? primaryPhoto,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
  }) async {
    final outbox = _outbox;
    final sync = _sync;
    if (outbox == null || sync == null) {
      throw StateError(
        'createReportQueued requires SiteReportService.forOutbox(...).',
      );
    }
    final payload = <String, dynamic>{
      'projectId': projectId,
      'title': title,
      'description': description,
      'reportType': reportType.toJson(),
      if (siteVisitId != null) 'siteVisitId': siteVisitId,
      if (taskId != null) 'taskId': taskId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAccuracy != null) 'locationAccuracy': locationAccuracy,
    };
    final id = await outbox.enqueue(
      type: OutboxMutationType.siteReportCreate,
      payload: payload,
      projectId: projectId,
      taskId: taskId,
      photo: primaryPhoto,
    );
    // Fire-and-forget: kick a background sync without blocking the queued result.
    unawaited(sync.triggerSyncNow());
    return SiteReportResultQueued(id);
  }

  /// Direct multipart POST — used on Flutter web where the offline outbox
  /// (Drift native backend) isn't available. Reads photos into memory and
  /// submits in one request. On mobile/desktop prefer [createReportQueued]
  /// so the upload survives connectivity loss.
  Future<SiteReport> createReportDirect({
    required int projectId,
    required String title,
    required String description,
    required ReportType reportType,
    int? siteVisitId,
    int? taskId,
    required List<XFile> photos,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
  }) async {
    if (photos.isEmpty) {
      throw ArgumentError('At least one photo is required');
    }
    final payload = <String, dynamic>{
      'projectId': projectId,
      'title': title,
      'description': description,
      'reportType': reportType.toJson(),
      if (siteVisitId != null) 'siteVisitId': siteVisitId,
      if (taskId != null) 'taskId': taskId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAccuracy != null) 'locationAccuracy': locationAccuracy,
    };

    final form = FormData();
    form.files.add(MapEntry(
      'report',
      MultipartFile.fromString(
        jsonEncode(payload),
        contentType: DioMediaType.parse('text/plain'),
      ),
    ));
    for (final photo in photos) {
      final bytes = await photo.readAsBytes();
      form.files.add(MapEntry(
        'photos',
        MultipartFile.fromBytes(bytes, filename: photo.name),
      ));
    }

    final response = await _apiService.post(
      '/api/site-reports',
      data: form,
    );
    return _apiService.unwrap(
        response, (json) => SiteReport.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteReport(int id) async {
    final response = await _apiService.delete('/api/site-reports/$id');
    _apiService.unwrap(response, (_) {});
  }

  Future<SiteReport> updateReport(int id, Map<String, dynamic> updateData) async {
    final response = await _apiService.put('/api/site-reports/$id', data: updateData);
    return _apiService.unwrap(
        response, (json) => SiteReport.fromJson(json as Map<String, dynamic>));
  }

  Future<SiteReport> addPhotosToReport(int reportId, List<XFile> photos) async {
    final formData = FormData();
    for (final file in photos) {
      formData.files.add(MapEntry(
        'photos',
        MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        ),
      ));
    }

    final response = await _apiService.post(
      '/api/site-reports/$reportId/photos',
      data: formData,
    );

    return _apiService.unwrap(
        response, (json) => SiteReport.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deletePhoto(int reportId, int photoId) async {
    final response = await _apiService.delete('/api/site-reports/$reportId/photos/$photoId');
    _apiService.unwrap(response, (_) {});
  }

  /// Standardized search endpoint for site reports.
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
