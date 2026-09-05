import 'package:flutter/material.dart';

import '../dashboard_page.dart';
import '../login_page.dart';
import '../screens/health_screen.dart';
import '../state/auth_state.dart';
import '../screens/detalle_reserva_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // ==========================================
    // Ruta dinámica: /detalle/:id
    // ==========================================
    final uri = Uri.parse(routeName);

    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'detalle') {
      final id = int.tryParse(uri.pathSegments[1]);

      if (id != null) {
        // La pantalla DetalleReservaPage se agregará
        // en el siguiente paso.
        return MaterialPageRoute(
          builder: (_) => DetalleReservaPage(id: id),
          settings: settings,
        );
      }
    }

    switch (settings.name) {
      // ==========================================
      // Ruta pública: Login
      // ==========================================
      case '/login':
        final destination = settings.arguments as String?;

        return MaterialPageRoute(
          builder: (_) => LoginPage(destination: destination),
          settings: settings,
        );

      // ==========================================
      // Ruta pública: Health
      // ==========================================
      case '/health':
        return MaterialPageRoute(
          builder: (_) => const HealthScreen(),
          settings: settings,
        );

      // ==========================================
      // Ruta protegida: Dashboard
      // ==========================================
      case '/inicio':
        if (!AuthState.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(destination: '/inicio'),
            settings: const RouteSettings(name: '/login'),
          );
        }

        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: settings,
        );

      // ==========================================
      // Ruta desconocida
      // ==========================================
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: const RouteSettings(name: '/login'),
        );
    }
  }
}
