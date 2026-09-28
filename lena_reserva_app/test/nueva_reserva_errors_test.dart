import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/services/api_service.dart';
import '../lib/screens/nueva_reserva_page.dart';

void main() {
  group('TEST 4 - Errores de formulario y servidor', () {
    testWidgets('1. Formulario inválido: muestra errores de validación', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: NuevaReservaPage()));

      await tester.tap(find.text('Crear reserva'));
      await tester.pump();

      expect(find.text('Seleccione un usuario'), findsOneWidget);
      expect(find.text('Seleccione una mesa'), findsOneWidget);
      expect(find.text('Ingrese el número de personas'), findsOneWidget);
    });

    testWidgets(
      '2. Error del servidor 422: ApiException contiene mensaje de validación',
      (tester) async {
        const exception = ApiException(
          422,
          'La cantidad de personas no es válida.',
          fieldErrors: {'personas': 'Debe ser mayor que 0'},
        );

        expect(exception.statusCode, 422);
        expect(exception.message, 'La cantidad de personas no es válida.');
        expect(exception.fieldErrors?['personas'], 'Debe ser mayor que 0');
      },
    );

    testWidgets('3. Error 422: puede mostrarse mediante SnackBar', (
      tester,
    ) async {
      const exception = ApiException(
        422,
        'Debe seleccionar una mesa disponible.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(exception.message)));
                  },
                  child: const Text('Mostrar error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar error'));
      await tester.pump();

      expect(
        find.text('Debe seleccionar una mesa disponible.'),
        findsOneWidget,
      );
    });
  });
}
