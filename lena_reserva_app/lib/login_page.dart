import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'services/api_service.dart';
import 'state/auth_controller.dart';

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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.redirectTo == '/app/reservas') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inicie sesión para consultar las reservas.'),
            ),
          );
        }
      });
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    final auth = AuthScope.of(context);
    try {
      final result = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      await auth.signIn(
        email: emailController.text.trim(),
        token: result['accessToken'].toString(),
        newRefreshToken: result['refreshToken']?.toString(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          widget.redirectTo ?? '/app/reservas',
        );
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(
          () => error = exception.statusCode == 401
              ? 'Correo o contraseña incorrectos.'
              : exception.message,
        );
      }
    } catch (_) {
      if (mounted)
        setState(() => error = 'No se pudo conectar con el servidor.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F7F6),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavButton(
            label: 'Login',
            active: widget.redirectTo != '/app/reservas',
            onPressed: () {},
          ),
          _NavButton(
            label: 'Registro',
            onPressed: () => Navigator.pushNamed(context, '/registro'),
          ),
          _NavButton(
            label: 'Reservas',
            active: widget.redirectTo == '/app/reservas',
            onPressed: () {
              final auth = AuthScope.of(context);
              if (auth.isAuthenticated) {
                Navigator.pushNamed(context, '/app/reservas');
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                  arguments: '/app/reservas',
                );
              }
            },
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
                borderRadius: BorderRadius.circular(12),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5E3E3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Ingrese un correo válido.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 4
                            ? 'La contraseña debe tener al menos 4 caracteres.'
                            : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : submit,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text('Ingresar'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {},
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
  Widget build(BuildContext context) => Padding(
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
