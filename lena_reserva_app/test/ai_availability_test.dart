import 'package:flutter_test/flutter_test.dart';
import 'package:lena_reserva_app/services/api_service.dart';

void main() {
  group('AIAvailability.fromJson', () {
    test('usa lista vacía cuando mesas no es una lista', () {
      final availability = AIAvailability.fromJson({
        'fecha': '2026-09-27',
        'cantidad': 0,
        'mesas': 'dato_invalido',
      });

      expect(availability.mesas, isEmpty);
      expect(availability.fecha, '2026-09-27');
      expect(availability.cantidad, 0);
    });

    test('convierte correctamente una lista de mesas', () {
      final availability = AIAvailability.fromJson({
        'fecha': '2026-09-27',
        'cantidad': 2,
        'mesas': [
          {'id': 1, 'numero': 'Mesa 1'},
          {'id': 2, 'numero': 'Mesa 2'},
        ],
      });

      expect(availability.mesas, hasLength(2));
      expect(availability.mesas[0]['id'], 1);
      expect(availability.mesas[1]['id'], 2);
    });
  });
}
