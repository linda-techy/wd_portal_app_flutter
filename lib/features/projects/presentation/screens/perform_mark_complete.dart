import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/local/photo_capture.dart';
import '../../../../models/site_report_models.dart';
import '../../../../services/location_service.dart';
import '../../../../services/outbox_service.dart';
import '../../../../services/site_report_service.dart';
import '../../data/services/task_completion_service.dart';
import '../../domain/mark_complete_outcome.dart';

/// Factory that builds the closure passed to
/// [TaskProgressEntryScreen.onMarkComplete]. The closure does:
///   1. Camera capture via [picker].pickImage → null/throw → cameraDenied.
///   2. GPS fix via [locationFetcher] → throw → gpsUnavailable.
///   3. Enqueue siteReportCreate row WITH photo + GPS via
///      [siteReportService.createReportQueued] → throw → outboxFailure.
///   4. Enqueue taskMarkComplete row WITHOUT photo via
///      [taskCompletionService.markCompleteQueued] → throw → outboxFailure
///      AND a compensating [outbox.deleteEntry] of the report row from step 3.
///
/// `picker` and `locationFetcher` are injectable seams so widget + unit tests
/// can stub the platform channels (`image_picker`, `geolocator`) without
/// hitting real hardware.
typedef LocationFetcher = Future<Position> Function();

Future<MarkCompleteOutcome> Function(int taskId, int? projectId)
    buildPerformMarkComplete({
  required OutboxService outbox,
  required TaskCompletionService taskCompletionService,
  required SiteReportService siteReportService,
  ImagePicker? picker,
  LocationFetcher? locationFetcher,
}) {
  final ImagePicker effectivePicker = picker ?? ImagePicker();
  final LocationFetcher effectiveLocation =
      locationFetcher ?? LocationService.getCurrentPosition;

  return (int taskId, int? projectId) async {
    // 1. Camera.
    XFile? xfile;
    try {
      xfile = await effectivePicker.pickImage(source: ImageSource.camera);
    } catch (_) {
      return MarkCompleteOutcome.failed(MarkCompleteError.cameraDenied);
    }
    if (xfile == null) {
      return MarkCompleteOutcome.failed(MarkCompleteError.cameraDenied);
    }

    // 2. GPS.
    Position position;
    try {
      position = await effectiveLocation();
    } on LocationException catch (e) {
      return MarkCompleteOutcome.failed(
          MarkCompleteError.gpsUnavailable, e.message);
    } catch (_) {
      return MarkCompleteOutcome.failed(MarkCompleteError.gpsUnavailable);
    }

    if (projectId == null) {
      return MarkCompleteOutcome.failed(
          MarkCompleteError.outboxFailure, 'Missing project id');
    }

    final photo = PhotoCapture(
      file: File(xfile.path),
      capturedAt: DateTime.now().toUtc(),
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );

    // 3. Enqueue site report (with photo). MUST be first so SyncService
    //    claims it before the mark-complete row.
    late final int reportEntryId;
    try {
      final result = await siteReportService.createReportQueued(
        projectId: projectId,
        title: 'Task completed',
        description: 'Geotagged completion evidence',
        reportType: ReportType.completion,
        taskId: taskId,
        primaryPhoto: photo,
        latitude: position.latitude,
        longitude: position.longitude,
        locationAccuracy: position.accuracy,
      );
      reportEntryId = (result as SiteReportResultQueued).outboxEntryId;
    } catch (_) {
      return MarkCompleteOutcome.failed(MarkCompleteError.outboxFailure);
    }

    // 4. Enqueue mark-complete (no photo). On failure, compensate by deleting
    //    the report row so SyncService doesn't dispatch a stranded
    //    COMPLETION report.
    try {
      final markCompleteEntryId =
          await taskCompletionService.markCompleteQueued(
        taskId: taskId,
        projectId: projectId,
      );
      return MarkCompleteOutcome.queued(reportEntryId, markCompleteEntryId);
    } catch (_) {
      try {
        await outbox.deleteEntry(reportEntryId);
      } catch (_) {
        // Best-effort. If even the rollback fails, the report row stays
        // and SyncService will deliver it standalone (harmless — server
        // accepts orphaned COMPLETION reports against IN_PROGRESS tasks
        // per S3 PR2 risk note).
      }
      return MarkCompleteOutcome.failed(MarkCompleteError.outboxFailure);
    }
  };
}
