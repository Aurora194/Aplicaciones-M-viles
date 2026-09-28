import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:lena_reserva_app/models/reservation.dart';
import 'package:lena_reserva_app/services/api_service.dart';

import 'helpers/fake_http_client.dart';

void main() {
  setUp(() {
    ApiService.resetClient();
  });

  tearDown(() {
    ApiService.resetClient();
  });

  group('ApiService - respuestas HTTP', () {
    test('1. Respuesta 200: crea correctamente una reserva', () async {
      final fakeClient = FakeHttpClient(
        statusCode: 200,
        body: jsonEncode({
          'data': {
            'id': 1,
            'fecha': '2026-10-15T19:00:00.000Z',
            'personas': 4,
            'estado': 'PENDIENTE',
            'mesaId': 2,
          },
        }),
      );

      ApiService.client = fakeClient;

      final reservation = await ApiService.createReservation(
        token: 'token-prueba',
        date: DateTime.utc(2026, 10, 15, 19),
        people: 4,
        userId: 10,
        tableId: 2,
      );

      expect(reservation, isA<Reservation>());
      expect(reservation.id, 1);
      expect(reservation.people, 4);
      expect(reservation.status, 'PENDIENTE');
      expect(reservation.tableId, 2);
    });

    test('2. Respuesta 401: genera ApiException de no autorizado', () async {
      final fakeClient = FakeHttpClient(
        statusCode: 401,
        body: jsonEncode({'message': 'Token inválido o expirado.'}),
      );

      ApiService.client = fakeClient;

      expect(
        () => ApiService.createReservation(
          token: 'token-expirado',
          date: DateTime.utc(2026, 10, 15, 19),
          people: 4,
          userId: 10,
          tableId: 2,
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Token inválido o expirado.',
              ),
        ),
      );
    });

    test('3. Respuesta 422: devuelve errores de validación', () async {
      final fakeClient = FakeHttpClient(
        statusCode: 422,
        body: jsonEncode({
          'message': 'Datos de reserva inválidos.',
          'errors': [
            {'path': 'personas', 'message': 'Debe ser entre 1 y 20.'},
          ],
        }),
      );

      ApiService.client = fakeClient;

      expect(
        () => ApiService.createReservation(
          token: 'token-prueba',
          date: DateTime.utc(2026, 10, 15, 19),
          people: 25,
          userId: 10,
          tableId: 2,
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.message,
                'message',
                'Datos de reserva inválidos.',
              )
              .having(
                (error) => error.fieldErrors['personas'],
                'error de personas',
                'Debe ser entre 1 y 20.',
              ),
        ),
      );
    });

    test('4. Timeout: propaga la excepción de tiempo de espera', () async {
      final fakeClient = FakeHttpClient(
        throwError: TimeoutException('Tiempo de espera agotado.'),
      );

      ApiService.client = fakeClient;

      expect(
        () => ApiService.createReservation(
          token: 'token-prueba',
          date: DateTime.utc(2026, 10, 15, 19),
          people: 4,
          userId: 10,
          tableId: 2,
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('5. Respuesta 401: renueva el token y reintenta la reserva', () async {
      final fakeClient = FakeHttpClient(
        responses: [
          // PRIMERA PETICIÓN:
          // accessToken expirado.
          FakeHttpResponse(
            statusCode: 401,
            body: jsonEncode({'message': 'Token inválido o expirado.'}),
          ),

          // SEGUNDA PETICIÓN:
          // renovación del accessToken.
          FakeHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'success': true,
              'accessToken': 'nuevo-access-token',
            }),
          ),

          // TERCERA PETICIÓN:
          // reintento de creación de reserva.
          FakeHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'data': {
                'id': 1,
                'fecha': '2026-10-15T19:00:00.000Z',
                'personas': 4,
                'estado': 'PENDIENTE',
                'mesaId': 2,
              },
            }),
          ),
        ],
      );

      ApiService.client = fakeClient;

      String? tokenActualizado;

      final reservation = await ApiService.createReservation(
        token: 'token-expirado',
        refreshToken: 'refresh-token-prueba',
        date: DateTime.utc(2026, 10, 15, 19),
        people: 4,
        userId: 10,
        tableId: 2,
        onTokenRefreshed: (newAccessToken) async {
          tokenActualizado = newAccessToken;
        },
      );

      // Verifica que finalmente se creó la reserva.
      expect(reservation, isA<Reservation>());
      expect(reservation.id, 1);
      expect(reservation.people, 4);
      expect(reservation.status, 'PENDIENTE');
      expect(reservation.tableId, 2);

      // Verifica que se recibió el nuevo accessToken.
      expect(tokenActualizado, 'nuevo-access-token');

      // Debieron realizarse exactamente 3 peticiones:
      //
      // 1. Crear reserva → 401
      // 2. Renovar token → 200
      // 3. Reintentar reserva → 200
      expect(fakeClient.requests.length, 3);

      // Primera petición: reserva con token expirado.
      expect(
        fakeClient.requests[0].headers['Authorization'],
        'Bearer token-expirado',
      );

      // Segunda petición: endpoint de renovación.
      expect(fakeClient.requests[1].url.path, '/api/auth/refresh');

      // Tercera petición: reserva nuevamente.
      expect(
        fakeClient.requests[2].headers['Authorization'],
        'Bearer nuevo-access-token',
      );

      // Verifica que el refreshToken se envió al endpoint correcto.
      final refreshRequest = fakeClient.requests[1];

      expect(refreshRequest, isA<http.Request>());

      final refreshBody = (refreshRequest as http.Request).body;

      final refreshJson = jsonDecode(refreshBody) as Map<String, dynamic>;

      expect(refreshJson['refreshToken'], 'refresh-token-prueba');
    });
  });
}
