import 'dart:io';
import 'package:admin/data/local/photo_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PhotoCapture stores file + optional gps + capturedAt', () {
    final capturedAt = DateTime.utc(2026, 5, 7, 9);
    final p = PhotoCapture(
      file: File('/tmp/x.jpg'),
      latitude: 12.97,
      longitude: 77.59,
      accuracyMeters: 5.0,
      capturedAt: capturedAt,
    );
    expect(p.file.path, '/tmp/x.jpg');
    expect(p.latitude, 12.97);
    expect(p.longitude, 77.59);
    expect(p.accuracyMeters, 5.0);
    expect(p.capturedAt, capturedAt);
  });

  test('PhotoCapture allows null gps fields', () {
    final p = PhotoCapture(file: File('/tmp/y.jpg'), capturedAt: DateTime.utc(2026, 5, 7));
    expect(p.latitude, isNull);
    expect(p.longitude, isNull);
    expect(p.accuracyMeters, isNull);
  });
}
