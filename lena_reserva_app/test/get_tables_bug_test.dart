import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lena_reserva_app/services/api_service.dart';

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  setUp(() {
    ApiService.client = FakeHttpClient((request) async {
      return http.Response(
        jsonEncode({'data': 'respuesta_invalida'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  tearDown(() {
    ApiService.resetClient();
  });

  test(
    'getTables debe devolver ApiException si data no es una lista',
    () async {
      expect(
        () => ApiService.getTables('test-token'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'La respuesta de mesas no contiene una lista.',
          ),
        ),
      );
    },
  );
}
