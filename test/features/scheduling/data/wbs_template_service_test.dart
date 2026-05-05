import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late WbsTemplateService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = WbsTemplateService(dio: dio);
  });

  test('list parses ApiResponse envelope and returns templates', () async {
    adapter.mock('GET', '/api/admin/wbs-templates', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}]}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final templates = await service.list();
    expect(templates, hasLength(1));
    expect(templates.first.code, 'RES');
    expect(templates.first.projectType, WbsProjectType.residential);
  });

  test('get returns a single template with phases', () async {
    adapter.mock('GET', '/api/admin/wbs-templates/1', (_) {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":2,"isActive":true,"phases":['
        '{"id":10,"sequence":1,"name":"Foundation","monsoonSensitive":false,"tasks":[]}'
        ']}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final t = await service.get(1);
    expect(t.version, 2);
    expect(t.phases, hasLength(1));
    expect(t.phases.first.name, 'Foundation');
  });

  test('createNewVersion POSTs the body and returns the new template', () async {
    adapter.mock('POST', '/api/admin/wbs-templates', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['code'], 'RES');
      expect(body['projectType'], 'RESIDENTIAL');
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":2,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential v2","version":2,"isActive":true,"phases":[]}}',
        201,
        headers: {'content-type': ['application/json']},
      );
    });

    const draft = WbsTemplate(
      code: 'RES',
      projectType: WbsProjectType.residential,
      name: 'Residential v2',
      version: 1,
      isActive: true,
      phases: [],
    );
    final created = await service.createNewVersion(draft);
    expect(created.id, 2);
    expect(created.version, 2);
  });

  test('cloneIntoProject POSTs to project endpoint and returns summary', () async {
    adapter.mock('POST', '/api/projects/42/wbs/clone-from-template', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['templateId'], 1);
      expect(body['floorCount'], 3);
      return ResponseBody.fromString(
        '{"success":true,"data":{"milestonesCreated":4,"tasksCreated":27,'
        '"predecessorsCreated":12}}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.cloneIntoProject(
      projectId: 42,
      templateId: 1,
      floorCount: 3,
    );
    expect(result.tasksCreated, 27);
    expect(result.milestonesCreated, 4);
  });

  test('delete sends DELETE request', () async {
    var called = false;
    adapter.mock('DELETE', '/api/admin/wbs-templates/3', (_) {
      called = true;
      return ResponseBody.fromString(
        '{"success":true}',
        200,
        headers: {'content-type': ['application/json']},
      );
    });
    await service.delete(3);
    expect(called, isTrue);
  });
}
