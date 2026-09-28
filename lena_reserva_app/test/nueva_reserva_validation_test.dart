import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lena_reserva_app/screens/nueva_reserva_page.dart';

void main() {
  Future<void> cargarPagina(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NuevaReservaPage()));

    await tester.pumpAndSettle();
  }

  Future<void> seleccionarUsuario(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButtonFormField<int>).at(0);

    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usuario #1').last);
    await tester.pumpAndSettle();
  }

  Future<void> seleccionarMesa(WidgetTester tester) async {
    final dropdown = find.byType(DropdownButtonFormField<int>).at(1);

    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mesa #1').last);
    await tester.pumpAndSettle();
  }

  group('NuevaReservaPage - validación del formulario', () {
    testWidgets(
      '1. Muestra errores cuando se intenta enviar el formulario vacío',
      (WidgetTester tester) async {
        await cargarPagina(tester);

        await tester.tap(find.text('Crear reserva'));

        await tester.pumpAndSettle();

        expect(find.text('Seleccione un usuario'), findsOneWidget);

        expect(find.text('Seleccione una mesa'), findsOneWidget);

        expect(find.text('Ingrese el número de personas'), findsOneWidget);
      },
    );

    testWidgets('2. Valida que el número de personas sea numérico', (
      WidgetTester tester,
    ) async {
      await cargarPagina(tester);

      await seleccionarUsuario(tester);
      await seleccionarMesa(tester);

      final campoPersonas = find.byType(TextFormField);

      await tester.enterText(campoPersonas, 'abc');

      await tester.tap(find.text('Crear reserva'));

      await tester.pumpAndSettle();

      expect(find.text('Ingrese un número válido'), findsOneWidget);
    });

    testWidgets('3. Valida que el número de personas sea mayor que cero', (
      WidgetTester tester,
    ) async {
      await cargarPagina(tester);

      await seleccionarUsuario(tester);
      await seleccionarMesa(tester);

      final campoPersonas = find.byType(TextFormField);

      await tester.enterText(campoPersonas, '0');

      await tester.tap(find.text('Crear reserva'));

      await tester.pumpAndSettle();

      expect(find.text('Debe ser mayor que 0'), findsOneWidget);
    });

    testWidgets('4. Acepta un número válido de personas', (
      WidgetTester tester,
    ) async {
      await cargarPagina(tester);

      await seleccionarUsuario(tester);
      await seleccionarMesa(tester);

      final campoPersonas = find.byType(TextFormField);

      await tester.enterText(campoPersonas, '4');

      await tester.tap(find.text('Crear reserva'));

      await tester.pumpAndSettle();

      expect(find.text('Seleccione fecha y hora'), findsOneWidget);
    });
  });
}
