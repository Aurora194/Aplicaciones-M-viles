import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'reservation_pages.dart';
import 'dashboard_page.dart';
import 'state/auth_controller.dart';
import 'theme/app_theme.dart';
import 'cliente_page.dart';
import 'mesas_page.dart';
import 'ai_page.dart';
import 'auth/auth_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthController();

  runApp(LenaReservaApp(auth: auth));

  // Restaurar la sesión después de crear la aplicación.
  auth.restore();
}

class LenaReservaApp extends StatelessWidget {
  const LenaReservaApp({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        // =====================================================
        // INFORMACIÓN DE LA APLICACIÓN
        // =====================================================
        title: 'Leña Reserva App',

        // =====================================================
        // TEMA
        // =====================================================
        theme: AppTheme.light(),

        // =====================================================
        // LOCALIZACIÓN EN ESPAÑOL
        // =====================================================
        locale: const Locale('es', 'ES'),

        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // =====================================================
        // PANTALLA INICIAL
        // =====================================================
        home: const AuthGate(),

        // =====================================================
        // RUTAS
        // =====================================================
        onGenerateRoute: (settings) {
          return _routes(settings, auth);
        },
      ),
    );
  }

  Route<dynamic> _routes(RouteSettings settings, AuthController controller) {
    final path = settings.name ?? '/';

    // =========================================================
    // RUTA PRINCIPAL
    // =========================================================

    if (path == '/') {
      return MaterialPageRoute(
        builder: (_) => const AuthGate(),
        settings: settings,
      );
    }

    // =========================================================
    // LOGIN
    // =========================================================

    if (path == '/login') {
      final redirect = settings.arguments is String
          ? settings.arguments as String
          : null;

      return MaterialPageRoute(
        builder: (_) => LoginPage(redirectTo: redirect),
        settings: settings,
      );
    }

    // =========================================================
    // REGISTRO
    // =========================================================

    if (path == '/registro') {
      return MaterialPageRoute(
        builder: (_) => const RegisterPage(),
        settings: settings,
      );
    }

    // =========================================================
    // ESTADO DE AUTENTICACIÓN
    // =========================================================

    final isAuthenticated = controller.isAuthenticated;

    // =========================================================
    // CLIENTE
    // =========================================================

    if (path == '/cliente') {
      if (!isAuthenticated) {
        return MaterialPageRoute(
          builder: (_) => const LoginPage(redirectTo: '/cliente'),
          settings: const RouteSettings(name: '/login'),
        );
      }

      if (controller.userRole == 'ADMIN') {
        return MaterialPageRoute(
          builder: (_) => const ReservationListPage(),
          settings: settings,
        );
      }

      return MaterialPageRoute(
        builder: (_) => const ClientePage(),
        settings: settings,
      );
    }

    // =========================================================
    // PROTEGER LAS RUTAS DE LA APLICACIÓN
    // =========================================================

    if (!isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => LoginPage(redirectTo: path),
        settings: RouteSettings(name: '/login', arguments: path),
      );
    }

    // =========================================================
    // INICIO
    // =========================================================

    if (path == '/inicio') {
      if (controller.userRole != 'ADMIN') {
        return MaterialPageRoute(
          builder: (_) => const ReservationListPage(),
          settings: settings,
        );
      }

      return MaterialPageRoute(
        builder: (_) => const DashboardPage(),
        settings: settings,
      );
    }

    // =========================================================
    // RESERVAS
    // =========================================================

    if (path == '/app/reservas') {
      return MaterialPageRoute(
        builder: (_) => const ReservationListPage(),
        settings: settings,
      );
    }

    // =========================================================
    // NUEVA RESERVA
    // =========================================================

    if (path == '/app/reservas/nueva') {
      return MaterialPageRoute(
        builder: (_) => const CreateReservationPage(),
        settings: settings,
      );
    }

    // =========================================================
    // GESTIONAR MESAS
    // =========================================================

    if (path == '/app/mesas') {
      return MaterialPageRoute(
        builder: (_) => const MesasPage(),
        settings: settings,
      );
    }

    // =========================================================
    // ASISTENTE IA
    // =========================================================

    if (path == '/app/ai') {
      return MaterialPageRoute(
        builder: (_) => const AIPage(),
        settings: settings,
      );
    }

    // =========================================================
    // DETALLE DE RESERVA
    // =========================================================

    final detail = RegExp(r'^/app/reservas/(\d+)$').firstMatch(path);

    if (detail != null) {
      return MaterialPageRoute(
        builder: (_) => ReservationDetailPage(id: int.parse(detail.group(1)!)),
        settings: settings,
      );
    }

    // =========================================================
    // RUTA NO ENCONTRADA
    // =========================================================

    return MaterialPageRoute(
      builder: (_) => const AuthGate(),
      settings: settings,
    );
  }
}

// ======================================================
// AUTH GATE
// ======================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    // --------------------------------------------------
    // ESPERAR A QUE SE RESTAURE LA SESIÓN
    // --------------------------------------------------

    if (!auth.isReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Leña Reserva App',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------
    // ERROR AL RESTAURAR
    // --------------------------------------------------

    if (auth.restoreError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(auth.restoreError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: auth.restore,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --------------------------------------------------
    // USUARIO AUTENTICADO
    // --------------------------------------------------

    if (auth.isAuthenticated) {
      return _landingPage(auth);
    }

    // --------------------------------------------------
    // SIN SESIÓN
    // --------------------------------------------------

    return const LoginPage();
  }

  Widget _landingPage(AuthController auth) {
    if (auth.userRole == 'ADMIN') {
      return const ReservationListPage();
    }

    return const ClientePage();
  }
}
