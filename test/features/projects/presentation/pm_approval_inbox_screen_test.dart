import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/features/projects/presentation/screens/pm_approval_inbox_screen.dart';
import 'package:admin/providers/permission_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

class _PermProv extends PermissionProvider {
  _PermProv(Set<String> perms) {
    setPermissions(perms.toList(), 'PROJECT_MANAGER');
  }
}

Widget wrapWithProviders({
  required Widget child,
  required PermissionProvider perm,
  required TaskCompletionService svc,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<PermissionProvider>.value(value: perm),
        Provider<TaskCompletionService>.value(value: svc),
      ],
      child: child,
    ),
  );
}

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late TaskCompletionService svc;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    svc = TaskCompletionService(dio: dio);
  });

  testWidgets('renders rows from /pending-pm-approval', (tester) async {
    adapter.mock('GET', '/api/tasks/pending-pm-approval', (_) {
      return ResponseBody.fromString(
        '[{"taskId":42,"taskTitle":"Beam casting","projectId":7,'
        '"projectName":"Villa Kochi","markedCompleteOn":"2026-05-04",'
        '"completionPhotoUrl":null}]',
        200, headers: {'content-type': ['application/json']});
    });

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(wrapWithProviders(
      child: const PmApprovalInboxScreen(),
      perm: _PermProv({'TASK_COMPLETION_APPROVE'}),
      svc: svc,
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Beam casting'), findsOneWidget);
    expect(find.textContaining('Villa Kochi'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Approve'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsOneWidget);
  });

  testWidgets('shows permission-denied placeholder without TASK_COMPLETION_APPROVE',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(wrapWithProviders(
      child: const PmApprovalInboxScreen(),
      perm: _PermProv({'TASK_VIEW'}),
      svc: svc,
    ));
    await tester.pump();

    expect(find.textContaining('not authorised'), findsOneWidget);
  });

  testWidgets('Approve calls service.approve and refreshes', (tester) async {
    int getCount = 0;
    bool approveCalled = false;
    adapter.mock('GET', '/api/tasks/pending-pm-approval', (_) {
      getCount++;
      // First call: 1 row; second call (post-approve refresh): empty.
      final body = getCount == 1
          ? '[{"taskId":42,"taskTitle":"Beam casting","projectId":7,'
              '"projectName":"Villa Kochi","markedCompleteOn":"2026-05-04",'
              '"completionPhotoUrl":null}]'
          : '[]';
      return ResponseBody.fromString(body, 200,
          headers: {'content-type': ['application/json']});
    });
    adapter.mock('POST', '/api/tasks/42/approve-completion', (_) {
      approveCalled = true;
      return ResponseBody.fromString(
        '{"id":42,"status":"COMPLETED"}', 200,
        headers: {'content-type': ['application/json']});
    });

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(wrapWithProviders(
      child: const PmApprovalInboxScreen(),
      perm: _PermProv({'TASK_COMPLETION_APPROVE'}),
      svc: svc,
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(approveCalled, isTrue);
    expect(getCount, 2);
  });

  testWidgets('Reject opens dialog, submits reason, calls service.reject',
      (tester) async {
    adapter.mock('GET', '/api/tasks/pending-pm-approval', (_) {
      return ResponseBody.fromString(
        '[{"taskId":42,"taskTitle":"Beam casting","projectId":7,'
        '"projectName":"Villa Kochi","markedCompleteOn":"2026-05-04",'
        '"completionPhotoUrl":null}]',
        200, headers: {'content-type': ['application/json']});
    });
    Map<String, dynamic>? rejectBody;
    adapter.mock('POST', '/api/tasks/42/reject-completion', (options) {
      rejectBody = options.data as Map<String, dynamic>;
      return ResponseBody.fromString(
        '{"id":42,"status":"IN_PROGRESS","rejectionReason":"Photo blurry"}',
        200, headers: {'content-type': ['application/json']});
    });

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(wrapWithProviders(
      child: const PmApprovalInboxScreen(),
      perm: _PermProv({'TASK_COMPLETION_APPROVE'}),
      svc: svc,
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Photo blurry, recapture');
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(rejectBody?['reason'], 'Photo blurry, recapture');
  });
}
