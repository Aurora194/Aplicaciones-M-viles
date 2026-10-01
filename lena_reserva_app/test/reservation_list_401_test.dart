import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lena_reserva_app/state/auth_controller.dart';
import 'package:lena_reserva_app/auth/auth_scope.dart';
import 'package:lena_reserva_app/reservation_pages.dart';
import 'package:lena_reserva_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class UnauthorizedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(
        '{"message":"No autorizado"}'.codeUnits,
      ),
      401,
      headers: const {
        'content-type': 'application/json',
      },
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ReservationListPage: HTTP 401 cierra sesión y navega a login',
    (tester) async {
      final originalClient = ApiService.client;
      ApiService.client = UnauthorizedClient();

      final auth = AuthController();

      addTearDown(() {
        ApiService.client = originalClient;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            auth: auth,
            child: const ReservationListPage(),
          ),
          routes: {
            '/login': (_) => const Scaffold(
                  body: Center(
                    child: Text('LOGIN_TEST'),
                  ),
                ),
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LOGIN_TEST'), findsOneWidget);
    },
  );
}