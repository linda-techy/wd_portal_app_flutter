import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/lead_estimation/data/services/estimation_options_service.dart';

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
    "addons": [
      {"id": "add-1", "name": "Smart Home", "description": "Automation package", "lumpAmount": 75000.00}
    ],
    "siteFees": [
      {"id": "sf-1", "name": "Sloped lot", "mode": "PER_SQFT", "lumpAmount": null, "perSqftRate": 50.00}
    ],
    "govtFees": [
      {"id": "gf-1", "name": "Building permit", "lumpAmount": 25000.00}
    ]
  }
}
''';

void main() {
  late Dio dio;
  late MockDioAdapter adapter;
  late EstimationOptionsService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
    adapter = MockDioAdapter();
    dio.httpClientAdapter = adapter;
    service = EstimationOptionsService(dio: dio);
  });

  test('get parses the nested envelope correctly', () async {
    adapter.mock('GET', '/api/estimation/options', (_) {
      return ResponseBody.fromString(
        _optionsJson,
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.get();

    expect(result.customisationCategories, hasLength(1));
    expect(result.customisationCategories.first.name, 'Kitchen Finish');
    expect(result.customisationCategories.first.pricingMode, 'PER_SQFT');
    expect(result.customisationCategories.first.options, hasLength(1));
    expect(result.customisationCategories.first.options.first.rate, 250.0);

    expect(result.addons, hasLength(1));
    expect(result.addons.first.name, 'Smart Home');
    expect(result.addons.first.lumpAmount, 75000.0);

    expect(result.siteFees, hasLength(1));
    expect(result.siteFees.first.mode, 'PER_SQFT');
    expect(result.siteFees.first.perSqftRate, 50.0);
    expect(result.siteFees.first.lumpAmount, isNull);

    expect(result.govtFees, hasLength(1));
    expect(result.govtFees.first.name, 'Building permit');
    expect(result.govtFees.first.lumpAmount, 25000.0);
  });

  test('get sends packageId query parameter', () async {
    adapter.mock('GET', '/api/estimation/options', (options) {
      expect(options.queryParameters['packageId'], 'pkg-42');
      return ResponseBody.fromString(
        _optionsJson,
        200,
        headers: {'content-type': ['application/json']},
      );
    });

    final result = await service.get(packageId: 'pkg-42');
    // Basic sanity: response still parses
    expect(result.customisationCategories, hasLength(1));
  });
}
