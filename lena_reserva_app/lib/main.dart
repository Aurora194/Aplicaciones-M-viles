import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'reservation_pages.dart';
import 'dashboard_page.dart';
import 'state/auth_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController()..restore();
  runApp(LenaReservaApp(auth: auth));
}

class LenaReservaApp extends StatelessWidget {
  const LenaReservaApp({super.key, this.auth});
  final AuthController? auth;

  @override
  Widget build(BuildContext context) {
    final controller = auth ?? (AuthController()..restore());
    return AuthScope(
        controller: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Leña Reserva App',
          theme: AppTheme.light(),
          home: const AuthGate(),
          onGenerateRoute: _routes,
        ));
  }

  Route<dynamic> _routes(RouteSettings settings) {
    final path = settings.name ?? '/';
    if (path == '/') return MaterialPageRoute(builder: (_) => const AuthGate());
    if (path == '/login') {
      return MaterialPageRoute(
        builder: (_) => LoginPage(redirectTo: settings.arguments as String?),
      );
    }
    if (path == '/registro') {
      return MaterialPageRoute(builder: (_) => const RegisterPage(), settings: settings);
    }
    final isAuthenticated = auth?.isAuthenticated ?? false;
    if (!isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => LoginPage(redirectTo: path),
        settings: RouteSettings(name: '/login', arguments: path),
      );
    }
    if (path == '/inicio') {
      return MaterialPageRoute(builder: (_) => const DashboardPage(), settings: settings);
    }
    if (path == '/app/reservas') {
      return MaterialPageRoute(builder: (_) => const ReservationListPage(), settings: settings);
    }
    if (path == '/app/reservas/nueva') {
      return MaterialPageRoute(builder: (_) => const CreateReservationPage(), settings: settings);
    }
    final detail = RegExp(r'^/app/reservas/(\d+)$').firstMatch(path);
    if (detail != null) {
      return MaterialPageRoute(
        builder: (_) => ReservationDetailPage(id: int.parse(detail.group(1)!)),
        settings: settings,
      );
    }
    return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (!auth.isReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Leña Reserva App'),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    if (auth.restoreError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(auth.restoreError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.restore,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return auth.isAuthenticated ? const DashboardPage() : const LoginPage();
  }
}
