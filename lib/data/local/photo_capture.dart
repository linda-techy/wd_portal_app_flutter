import 'dart:io';

/// A snapshot the site engineer captures via image_picker + geolocator.
/// Consumed by [OutboxService.enqueue] which copies the file into the
/// outbox photo directory and persists path + GPS in the Drift row.
class PhotoCapture {
  PhotoCapture({
    required this.file,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  final File file;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
}
