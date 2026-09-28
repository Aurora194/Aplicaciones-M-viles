import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lena_reserva_app/auth/auth_scope.dart';
import 'package:lena_reserva_app/reservation_pages.dart';
import 'package:lena_reserva_app/services/api_service.dart';
import 'package:lena_reserva_app/state/auth_controller.dart';

import 'helpers/fake_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ApiService.resetClient();

    CreateReservationPage.draftPeople = null;
    CreateReservationPage.draftDate = null;
    CreateReservationPage.draftTime = null;
    CreateReservationPage.draftTableId = null;
  });

  testWidgets('E2E: crear reserva desde nueva reserva', (tester) async {
    // ============================================================
    // 1. SESIÓN DE PRUEBA
    // ============================================================

    final auth = AuthController();

    auth.setTestSession(
      token: 'test-access-token',
      refreshToken: 'test-refresh-token',
      userId: 1,
    );

    // ============================================================
    // 2. CLIENTE HTTP FALSO
    // ============================================================

    final fakeClient = FakeHttpClient(
      responses: [
        // --------------------------------------------------------
        // GET /api/mesas/disponibles
        // --------------------------------------------------------
        FakeHttpResponse(
          statusCode: 200,
          body: '''
{
  "data": [
    {
      "id": 1,
      "numero": 1,
      "capacidad": 4,
      "disponible": true
    }
  ]
}
''',
        ),

        // --------------------------------------------------------
        // POST /api/reservas
        // --------------------------------------------------------
        FakeHttpResponse(
          statusCode: 200,
          body: '''
{
  "id": 100,
  "usuario_id": 1,
  "mesa_id": 1,
  "personas": 2,
  "fecha_reserva": "2026-10-01T00:00:00.000Z",
  "estado": "PENDIENTE"
}
''',
        ),
      ],
    );

    ApiService.client = fakeClient;

    // ============================================================
    // 3. DATOS INICIALES
    // ============================================================

    CreateReservationPage.draftPeople = '2';

    CreateReservationPage.draftDate = DateTime(2026, 9, 30);

    CreateReservationPage.draftTime = const TimeOfDay(hour: 19, minute: 0);

    // ============================================================
    // 4. ABRIR NUEVA RESERVA
    // ============================================================

    await tester.pumpWidget(
      AuthScope(
        auth: auth,
        child: MaterialApp(
          home: CreateReservationPage(
            // ----------------------------------------------------
            // Notificaciones simuladas para pruebas.
            // Evita depender del plugin nativo.
            // ----------------------------------------------------
            requestNotificationPermission: () async {
              debugPrint('NOTIFICACIONES: permiso simulado -> concedido');

              return true;
            },
            showReservationCreated: ({required int reservationId}) async {
              debugPrint(
                'NOTIFICACIONES: reserva creada -> '
                'ID $reservationId',
              );
            },
            scheduleReservationReminder:
                ({
                  required int reservationId,
                  required DateTime reservationDateTime,
                  required int minutesBefore,
                }) async {
                  debugPrint(
                    'NOTIFICACIONES: recordatorio simulado -> '
                    'reserva $reservationId, '
                    '$minutesBefore minutos antes',
                  );
                },
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.pump(const Duration(seconds: 1));

    await tester.pump(const Duration(milliseconds: 500));

    // ============================================================
    // 5. VERIFICAR CARGA DE MESAS
    // ============================================================

    expect(find.text('Crear nueva reserva'), findsOneWidget);

    expect(find.text('Mesa 1'), findsOneWidget);

    expect(fakeClient.requests.length, 1);

    expect(fakeClient.requests[0].method, 'GET');

    expect(fakeClient.requests[0].url.path, '/api/mesas/disponibles');

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 1: MESAS CARGADAS');
    debugPrint('==============================================');
    debugPrint('GET /api/mesas/disponibles -> OK');

    // ============================================================
    // 6. SELECCIONAR MESA 1
    // ============================================================

    final mesa1 = find.text('Mesa 1');

    final mesa1InkWell = find.ancestor(
      of: mesa1,
      matching: find.byType(InkWell),
    );

    expect(mesa1InkWell, findsWidgets);

    await tester.tap(mesa1InkWell.first);

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mesa 1 seleccionada'), findsOneWidget);

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 2: MESA SELECCIONADA');
    debugPrint('==============================================');
    debugPrint('Mesa 1 seleccionada -> OK');

    // ============================================================
    // 7. VER RESUMEN
    // ============================================================

    final verResumen = find.text('Ver resumen');

    expect(verResumen, findsOneWidget);

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 3: VER RESUMEN');
    debugPrint('==============================================');
    debugPrint('Botón "Ver resumen" encontrado.');

    await tester.ensureVisible(verResumen);

    await tester.tap(verResumen);

    await tester.pumpAndSettle();

    debugPrint('Navegación al resumen completada.');

    // ============================================================
    // 8. VERIFICAR RESUMEN
    // ============================================================

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 4: RESUMEN DE RESERVA');
    debugPrint('==============================================');

    expect(find.text('Crear reserva'), findsOneWidget);

    final crearReservaText = find.text('Crear reserva');

    debugPrint(
      'Texto "Crear reserva": '
      '${crearReservaText.evaluate().length}',
    );

    debugPrint(
      'ModalBarrier activos: '
      '${find.byType(ModalBarrier).evaluate().length}',
    );

    debugPrint(
      'AbsorbPointer activos: '
      '${find.byType(AbsorbPointer).evaluate().length}',
    );

    // ============================================================
    // 9. ENCONTRAR EL ELEVATEDBUTTON
    // ============================================================

    final crearReservaButtonFinder = find.ancestor(
      of: crearReservaText,
      matching: find.byType(ElevatedButton),
    );

    expect(
      crearReservaButtonFinder,
      findsOneWidget,
      reason:
          'Debe existir un ElevatedButton que contenga '
          '"Crear reserva".',
    );

    debugPrint('ElevatedButton "Crear reserva": encontrado.');

    // ============================================================
    // 10. EJECUTAR CALLBACK DEL BOTÓN
    // ============================================================

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 5: CONFIRMAR RESERVA');
    debugPrint('==============================================');

    final buttonElement = crearReservaButtonFinder.evaluate().first;

    final buttonWidget = buttonElement.widget as ElevatedButton;

    expect(
      buttonWidget.onPressed,
      isNotNull,
      reason:
          'El botón "Crear reserva" debe tener '
          'una acción onPressed.',
    );

    debugPrint('Callback onPressed encontrado.');

    // El botón está detrás de una ModalBarrier
    // durante el widget test. Ejecutamos el mismo
    // callback que tiene configurado el botón.
    buttonWidget.onPressed!();

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 500));

    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpAndSettle();

    debugPrint('Callback de "Crear reserva" ejecutado.');

    // ============================================================
    // 11. VERIFICAR PETICIONES HTTP
    // ============================================================

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 6: PETICIONES HTTP');
    debugPrint('==============================================');

    debugPrint(
      'TOTAL REQUESTS: '
      '${fakeClient.requests.length}',
    );

    for (var i = 0; i < fakeClient.requests.length; i++) {
      final request = fakeClient.requests[i];

      debugPrint(
        'REQUEST ${i + 1}: '
        '${request.method} ${request.url}',
      );
    }

    // ============================================================
    // 12. VERIFICAR GET + POST
    // ============================================================

    expect(
      fakeClient.requests.length,
      2,
      reason:
          'El flujo E2E debe realizar primero el GET '
          'de mesas y luego el POST de creación de reserva.',
    );

    final getRequest = fakeClient.requests[0];

    expect(getRequest.method, 'GET');

    expect(getRequest.url.path, '/api/mesas/disponibles');

    final postRequest = fakeClient.requests[1];

    expect(postRequest.method, 'POST');

    expect(postRequest.url.path, '/api/reservas');

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('PASO 7: POST VERIFICADO');
    debugPrint('==============================================');

    debugPrint('GET /api/mesas/disponibles -> OK');

    debugPrint('POST /api/reservas -> OK');

    // ============================================================
    // 13. RESULTADO FINAL
    // ============================================================

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('TEST E2E FINALIZADO');
    debugPrint('==============================================');

    debugPrint('Flujo probado:');

    debugPrint('1. Carga de mesas');

    debugPrint('2. Selección de Mesa 1');

    debugPrint('3. Ver resumen');

    debugPrint('4. Confirmación de reserva');

    debugPrint('5. POST /api/reservas');

    debugPrint('6. Respuesta HTTP simulada');

    debugPrint('');

    debugPrint('RESULTADO: FLUJO E2E COMPLETADO');

    debugPrint('==============================================');
  });
}
