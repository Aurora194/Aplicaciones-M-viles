import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP falso utilizado exclusivamente para pruebas.
///
/// Permite simular:
/// - respuestas exitosas 200
/// - errores 401
/// - errores 422
/// - timeout
/// - secuencia de respuestas para probar renovación de token
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient({
    this.statusCode = 200,
    this.body = '{}',
    this.headers = const {'content-type': 'application/json; charset=utf-8'},
    this.delay,
    this.throwError,
    this.responses,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  /// Permite simular una respuesta lenta.
  final Duration? delay;

  /// Permite simular una excepción de transporte.
  final Object? throwError;

  /// Permite simular varias respuestas consecutivas.
  ///
  /// Ejemplo:
  /// 1. 401
  /// 2. 200 renovación
  /// 3. 200 reserva
  final List<FakeHttpResponse>? responses;

  /// Guarda las peticiones realizadas para poder verificarlas
  /// desde las pruebas.
  final List<http.BaseRequest> requests = [];

  bool _closed = false;
  int _responseIndex = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) {
      throw StateError('FakeHttpClient ya fue cerrado.');
    }

    // Guarda la petición para poder verificarla en los tests.
    requests.add(request);

    // Simula una excepción de transporte.
    if (throwError != null) {
      throw throwError!;
    }

    // Simula una respuesta lenta si se especificó un retraso.
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }

    // =========================================================
    // RESPUESTAS EN SECUENCIA
    // =========================================================

    if (responses != null && _responseIndex < responses!.length) {
      final fakeResponse = responses![_responseIndex];

      _responseIndex++;

      final bytes = utf8.encode(fakeResponse.body);

      final stream = http.ByteStream.fromBytes(bytes);

      return http.StreamedResponse(
        stream,
        fakeResponse.statusCode,
        headers: fakeResponse.headers,
        request: request,
        reasonPhrase: _reasonPhrase(fakeResponse.statusCode),
      );
    }

    // =========================================================
    // RESPUESTA INDIVIDUAL
    // =========================================================

    final bytes = utf8.encode(body);

    final stream = http.ByteStream.fromBytes(bytes);

    return http.StreamedResponse(
      stream,
      statusCode,
      headers: headers,
      request: request,
      reasonPhrase: _reasonPhrase(statusCode),
    );
  }

  String _reasonPhrase(int code) {
    switch (code) {
      case 200:
        return 'OK';

      case 201:
        return 'Created';

      case 400:
        return 'Bad Request';

      case 401:
        return 'Unauthorized';

      case 403:
        return 'Forbidden';

      case 404:
        return 'Not Found';

      case 422:
        return 'Unprocessable Entity';

      case 500:
        return 'Internal Server Error';

      default:
        return 'HTTP $code';
    }
  }

  @override
  void close() {
    _closed = true;
  }
}

/// Representa una respuesta HTTP falsa para las pruebas.
class FakeHttpResponse {
  const FakeHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {'content-type': 'application/json; charset=utf-8'},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}
