import 'package:flutter_test/flutter_test.dart';

import 'package:lena_reserva_app/main.dart';
import 'package:lena_reserva_app/state/auth_controller.dart';

void main() {
  testWidgets('Lena Reserva App inicia correctamente', (
    WidgetTester tester,
  ) async {
    final auth = AuthController();

    await tester.pumpWidget(LenaReservaApp(auth: auth));

    await tester.pump();

    expect(find.text('Leña Reserva'), findsWidgets);
  });
}
