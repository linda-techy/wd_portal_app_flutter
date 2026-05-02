import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/lead_estimation/data/services/estimation_options_service.dart';
import 'package:admin/features/lead_estimation/providers/estimation_options_provider.dart';

import '../../../test_helpers/mock_dio_adapter.dart';

const _optionsJson = '''
{
  "success": true,
  "message": "OK",
  "data": {
    "customisationCategories": [
      {
        "id": "cat-1",
        "name": "Kitchen Finish",
        "pricingMode": "PER_SQFT",
        "displayOrder": 1,
        "options": [
          {"id": "opt-1", "categoryId": "cat-1", "name": "Standard", "rate": 250.00, "displayOrder": 1}
        ]
      }
    ],
    "addons": [],
    "siteFees": [],
    "govtFees": []
  }
}
''';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late EstimationOptionsProvider provider;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    provider = EstimationOptionsProvider(
      service: EstimationOptionsService(dio: dio),
    );
  });

  test('loadForPackage populates options and clears loading state', () async {
    adapter.mock('GET', '/api/estimation/options', (_) {
      return ResponseBody.fromString(
        _optionsJson,
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.loadForPackage('pkg-1');

    expect(provider.options, isNotNull);
    expect(provider.options!.customisationCategories, hasLength(1));
    expect(provider.options!.customisationCategories.first.name, 'Kitchen Finish');
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('loadForPackage 403 captures friendly error', () async {
    adapter.mock('GET', '/api/estimation/options', (_) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Forbidden"}',
        403,
        headers: {'content-type': ['application/json']},
      );
    });

    await provider.loadForPackage(null);

    expect(provider.options, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, contains('permission'));
  });
}
