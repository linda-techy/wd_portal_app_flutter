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

  test('list calls real backend URL with includeInactive only', () async {
    adapter.mock('GET', '/api/wbs/templates', (options) {
      // Real backend exposes only `includeInactive` (boolean).
      expect(options.queryParameters['includeInactive'], false);
      expect(options.queryParameters.containsKey('projectType'), isFalse);
      expect(options.queryParameters.containsKey('activeOnly'), isFalse);
      return ResponseBody.fromString(
        '[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final templates = await service.list();
    expect(templates, hasLength(1));
    expect(templates.first.code, 'RES');
    expect(templates.first.projectType, WbsProjectType.residential);
  });

  test('list passes includeInactive=true through', () async {
    adapter.mock('GET', '/api/wbs/templates', (options) {
      expect(options.queryParameters['includeInactive'], true);
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final out = await service.list(includeInactive: true);
    expect(out, isEmpty);
  });

  test('get returns a single template with phases (raw body)', () async {
    adapter.mock('GET', '/api/wbs/templates/1', (_) {
      return ResponseBody.fromString(
        '{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":2,"isActive":true,"phases":['
        '{"id":10,"sequence":1,"name":"Foundation","monsoonSensitive":false,"tasks":[]}'
        ']}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    final t = await service.get(1);
    expect(t.version, 2);
    expect(t.phases, hasLength(1));
    expect(t.phases.first.name, 'Foundation');
  });

  test('createNewVersion POSTs to /api/wbs/templates and returns DTO',
      () async {
    adapter.mock('POST', '/api/wbs/templates', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['code'], 'RES');
      expect(body['projectType'], 'RESIDENTIAL');
      return ResponseBody.fromString(
        '{"id":2,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential v2","version":2,"isActive":true,"phases":[]}',
        201,
        headers: {
          'content-type': ['application/json']
        },
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

  test('update PUTs full DTO to /api/wbs/templates/{id}', () async {
    adapter.mock('PUT', '/api/wbs/templates/3', (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['code'], 'RES');
      expect(body['isActive'], false);
      return ResponseBody.fromString(
        '{"id":3,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":2,"isActive":false,"phases":[]}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });

    const dto = WbsTemplate(
      id: 3,
      code: 'RES',
      projectType: WbsProjectType.residential,
      name: 'R',
      version: 2,
      isActive: false,
      phases: [],
    );
    final saved = await service.update(3, dto);
    expect(saved.isActive, isFalse);
  });

  test('cloneIntoProject POSTs to project endpoint and returns summary',
      () async {
    adapter.mock('POST', '/api/projects/42/wbs/clone-from-template',
        (options) {
      final body = options.data as Map<String, dynamic>;
      expect(body['templateId'], 1);
      expect(body['floorCount'], 3);
      return ResponseBody.fromString(
        '{"milestonesCreated":4,"tasksCreated":27,"predecessorsCreated":12}',
        200,
        headers: {
          'content-type': ['application/json']
        },
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

  test('delete sends DELETE request to /api/wbs/templates/{id}', () async {
    var called = false;
    adapter.mock('DELETE', '/api/wbs/templates/3', (_) {
      called = true;
      return ResponseBody.fromString(
        '',
        204,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await service.delete(3);
    expect(called, isTrue);
  });
}
