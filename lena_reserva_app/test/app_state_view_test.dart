import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lena_reserva_app/widgets/app_state_view.dart';

void main() {
  group('AppStateView - estados de pantalla', () {
    testWidgets('1. Estado loading: muestra indicador de carga', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppStateView(state: AppViewState.loading)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      expect(find.bySemanticsLabel('Cargando información'), findsOneWidget);
    });

    testWidgets('2. Estado empty: muestra mensaje de información vacía', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              state: AppViewState.empty,
              message: 'No existen reservas disponibles.',
            ),
          ),
        ),
      );

      expect(find.text('No existen reservas disponibles.'), findsOneWidget);
    });

    testWidgets('3. Estado error: muestra mensaje y botón Reintentar', (
      WidgetTester tester,
    ) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppStateView(
              state: AppViewState.error,
              message: 'No se pudo cargar la información.',
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No se pudo cargar la información.'), findsOneWidget);

      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('4. Estado success: muestra el contenido', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              state: AppViewState.success,
              child: Text('Reservas cargadas correctamente'),
            ),
          ),
        ),
      );

      expect(find.text('Reservas cargadas correctamente'), findsOneWidget);
    });
  });
}
