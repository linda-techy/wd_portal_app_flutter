import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/scheduling/data/services/wbs_template_service.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/providers/wbs_template_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late WbsTemplateProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = WbsTemplateProvider(service: WbsTemplateService(dio: dio));
  });

  test('loadList populates list and clears loading', () async {
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadList();
    expect(provider.templates, hasLength(1));
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('loadList captures 403 as a friendly error', () async {
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '"Forbidden"',
        403,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadList();
    expect(provider.templates, isEmpty);
    expect(provider.errorMessage, contains('permission'));
  });

  test('client-side projectType filter narrows results', () async {
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '[{"id":1,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential","version":1,"isActive":true,"phases":[]},'
        '{"id":2,"code":"COMM","projectType":"COMMERCIAL",'
        '"name":"Commercial","version":1,"isActive":true,"phases":[]}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadList(projectType: WbsProjectType.residential);
    expect(provider.templates, hasLength(1));
    expect(provider.templates.first.projectType, WbsProjectType.residential);
  });

  test('loadEditing fetches by id and stores it as the editing draft',
      () async {
    adapter.mock('GET', '/api/wbs/templates/3', (_) {
      return ResponseBody.fromString(
        '{"id":3,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"Residential v2","version":2,"isActive":true,"phases":['
        '{"id":10,"sequence":1,"name":"Foundation","monsoonSensitive":false,"tasks":[]}'
        ']}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadEditing(3);
    expect(provider.editing, isNotNull);
    expect(provider.editing!.phases, hasLength(1));
  });

  test('updateEditing replaces draft and notifies', () async {
    adapter.mock('GET', '/api/wbs/templates/3', (_) {
      return ResponseBody.fromString(
        '{"id":3,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":1,"isActive":true,"phases":[]}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadEditing(3);
    var notified = 0;
    provider.addListener(() => notified++);
    provider.updateEditing(provider.editing!.copyWith(name: 'R2'));
    expect(provider.editing!.name, 'R2');
    expect(notified, 1);
  });

  test('saveEditing POSTs draft as new version', () async {
    adapter.mock('POST', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '{"id":4,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":2,"isActive":true,"phases":[]}',
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    // Background loadList that saveEditing kicks off
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    provider.updateEditing(const WbsTemplate(
      code: 'RES',
      projectType: WbsProjectType.residential,
      name: 'R',
      version: 1,
      isActive: true,
      phases: [],
    ));
    final saved = await provider.saveEditing();
    expect(saved, isTrue);
    expect(provider.editing!.id, 4);
    expect(provider.editing!.version, 2);
  });

  test('setActive GETs current DTO and PUTs the toggled copy', () async {
    // Seed the list with one template.
    adapter.mock('GET', '/api/wbs/templates', (_) {
      return ResponseBody.fromString(
        '[{"id":7,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":1,"isActive":true,"phases":[]}]',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    await provider.loadList();

    adapter.mock('GET', '/api/wbs/templates/7', (_) {
      return ResponseBody.fromString(
        '{"id":7,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":1,"isActive":true,"phases":[]}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    var putBody = <String, dynamic>{};
    adapter.mock('PUT', '/api/wbs/templates/7', (options) {
      putBody = options.data as Map<String, dynamic>;
      return ResponseBody.fromString(
        '{"id":7,"code":"RES","projectType":"RESIDENTIAL",'
        '"name":"R","version":1,"isActive":false,"phases":[]}',
        200,
        headers: {
          'content-type': ['application/json']
        },
      );
    });
    final ok = await provider.setActive(7, false);
    expect(ok, isTrue);
    expect(putBody['isActive'], isFalse);
    expect(provider.templates.first.isActive, isFalse);
  });
}
