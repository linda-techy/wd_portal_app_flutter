import 'package:dio/dio.dart';

/// Lightweight Dio HTTP client adapter for tests.
///
/// Register handlers per `(method, path)` pair via [mock]; each handler
/// receives the [RequestOptions] (so it can assert on body/query) and
/// returns a [ResponseBody].
///
/// Example:
/// ```dart
/// final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
/// final adapter = MockDioAdapter();
/// dio.httpClientAdapter = adapter;
///
/// adapter.mock('GET', '/api/foo', (_) => ResponseBody.fromString(
///   '{"success":true,"data":[]}', 200,
///   headers: {'content-type': ['application/json']},
/// ));
/// ```
class MockDioAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _handlers = {};

  void mock(String method, String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['$method $path'] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final handler = _handlers['${options.method} ${options.path}'];
    if (handler == null) {
      throw StateError('No mock for ${options.method} ${options.path}');
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
