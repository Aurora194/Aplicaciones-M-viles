import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'services/api_service.dart';
import 'forgot_password_page.dart';
import 'auth/auth_scope.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, String? redirectTo, String? destination})
    : redirectTo = redirectTo ?? destination;

  final String? redirectTo;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  String? error;

  @override
  void initState() {
    super.initState();

    if (widget.redirectTo == '/app/reservas') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicie sesión para consultar las reservas.'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
    });

    final auth = AuthScope.of(context);

    try {
      // =========================================================
      // 1. LOGIN CONTRA EL BACKEND
      // =========================================================

      final result = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      final accessToken = result['accessToken']?.toString();
      final refreshToken = result['refreshToken']?.toString();

      // =========================================================
      // 2. VALIDAR TOKEN
      // =========================================================

      if (accessToken == null || accessToken.isEmpty || accessToken == 'null') {
        if (!mounted) return;

        setState(() {
          error =
              'El servidor respondió correctamente, pero no devolvió el token de acceso.';
          loading = false;
        });

        return;
      }

      // =========================================================
      // 3. OBTENER DATOS DEL USUARIO
      // =========================================================

      final usuario = result['usuario'];

      String? role;
      int? userId;
      String? userName;
      String? userLastName;

      if (usuario is Map) {
        final rawRole = usuario['rol']?.toString();

        if (rawRole != null && rawRole.trim().isNotEmpty) {
          role = rawRole.trim().toUpperCase();
        }

        final rawId = usuario['id'];

        if (rawId is num) {
          userId = rawId.toInt();
        } else {
          userId = int.tryParse(rawId?.toString() ?? '');
        }

        userName = usuario['nombre']?.toString();
        userLastName = usuario['apellido']?.toString();
      }

      debugPrint('Usuario recibido: $usuario');
      debugPrint('ID recibido: $userId');
      debugPrint('Rol recibido desde backend: $role');
      debugPrint('Nombre recibido: $userName');
      debugPrint('Apellido recibido: $userLastName');

      // =========================================================
      // 4. GUARDAR SESIÓN
      // =========================================================

      try {
        await auth.signIn(
          email: emailController.text.trim(),
          token: accessToken,
          newRefreshToken: refreshToken,
          role: role,
          id: userId,
          name: userName,
          lastName: userLastName,
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          error = 'No se pudo guardar la sesión en el dispositivo.\n$e';
          loading = false;
        });

        return;
      }

      if (!mounted) return;

      // =========================================================
      // 5. DETERMINAR DESTINO
      // =========================================================

      final destination =
          widget.redirectTo == null || widget.redirectTo == '/inicio'
          ? auth.landingRoute
          : widget.redirectTo!;

      debugPrint('========================================');
      debugPrint('LOGIN EXITOSO');
      debugPrint('Usuario: ${auth.userName}');
      debugPrint('Correo: ${auth.userEmail}');
      debugPrint('ID: ${auth.userId}');
      debugPrint('Rol: ${auth.userRole}');
      debugPrint('Autenticado: ${auth.isAuthenticated}');
      debugPrint('Destino: $destination');
      debugPrint('========================================');

      // =========================================================
      // 6. NAVEGAR
      // =========================================================

      try {
        await Navigator.pushReplacementNamed(context, destination);
      } catch (e) {
        if (!mounted) return;

        debugPrint('Error de navegación después del login: $e');

        setState(() {
          error =
              'El inicio de sesión fue correcto, pero no se pudo abrir la pantalla "$destination".\n$e';
          loading = false;
        });

        return;
      }
    } on ApiException catch (exception) {
      if (!mounted) return;

      debugPrint(
        'ApiException en login: '
        '${exception.statusCode} - ${exception.message}',
      );

      setState(() {
        if (exception.statusCode == 401) {
          error = 'Correo o contraseña incorrectos.';
        } else {
          error = exception.message;
        }

        loading = false;
      });

      return;
    } catch (e, stackTrace) {
      if (!mounted) return;

      debugPrint('Error inesperado en login: $e');

      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        error = 'Ocurrió un error inesperado durante el inicio de sesión.\n$e';
        loading = false;
      });

      return;
    }
  }

  void _openReservations() {
    final auth = AuthScope.of(context);

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/app/reservas');

      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: '/app/reservas',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavButton(label: 'Login', active: true, onPressed: () {}),
            _NavButton(
              label: 'Registro',
              onPressed: () {
                Navigator.pushNamed(context, '/registro');
              },
            ),
            _NavButton(
              label: 'Reservas',
              active: widget.redirectTo == '/app/reservas',
              onPressed: _openReservations,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 38, 32, 34),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: AppColors.primary,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Leña Reserva App',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),

                        const SizedBox(height: 30),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Ingrese un correo válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          enabled: !loading,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 4) {
                              return 'La contraseña debe tener al menos 4 caracteres.';
                            }

                            return null;
                          },
                        ),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : submit,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Ingresar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: active
              ? Colors.black87
              : Theme.of(context).colorScheme.primary,
          backgroundColor: active ? Colors.black12 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}
