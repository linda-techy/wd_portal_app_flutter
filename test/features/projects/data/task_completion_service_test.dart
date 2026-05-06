import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late TaskCompletionService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = TaskCompletionService(dio: dio);
  });

  test('markComplete POSTs the right URL and returns status', () async {
    adapter.mock('POST', '/api/tasks/42/mark-complete', (options) {
      return ResponseBody.fromString(
        '{"id":42,"status":"PENDING_PM_APPROVAL"}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final status = await service.markComplete(42);
    expect(status, 'PENDING_PM_APPROVAL');
  });

  test('approve POSTs the right URL', () async {
    adapter.mock('POST', '/api/tasks/42/approve-completion', (options) {
      return ResponseBody.fromString(
        '{"id":42,"status":"COMPLETED"}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final status = await service.approve(42);
    expect(status, 'COMPLETED');
  });

  test('reject POSTs reason in body', () async {
    Map<String, dynamic>? captured;
    adapter.mock('POST', '/api/tasks/42/reject-completion', (options) {
      captured = options.data as Map<String, dynamic>;
      return ResponseBody.fromString(
        '{"id":42,"status":"IN_PROGRESS","rejectionReason":"Photo blurry"}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final status = await service.reject(42, 'Photo blurry');
    expect(status, 'IN_PROGRESS');
    expect(captured?['reason'], 'Photo blurry');
  });

  test('pendingApprovalInbox parses row list', () async {
    adapter.mock('GET', '/api/tasks/pending-pm-approval', (options) {
      return ResponseBody.fromString(
        '[{"taskId":42,"taskTitle":"Beam casting","projectId":7,'
        '"projectName":"Villa Kochi","markedCompleteOn":"2026-05-04",'
        '"completionPhotoUrl":"/api/storage/site-reports/42/abc.jpg"}]',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final rows = await service.pendingApprovalInbox();
    expect(rows, hasLength(1));
    expect(rows.first.taskId, 42);
    expect(rows.first.completionPhotoUrl, '/api/storage/site-reports/42/abc.jpg');
    expect(rows.first.markedCompleteOn, DateTime(2026, 5, 4));
  });
}
