import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    // Si el backend devolvió HTML, devolver un mensaje más legible
    if (msg.contains('<!DOCTYPE') || msg.contains('<html')) {
      return 'Error del servidor: respuesta inesperada.';
    }
    return msg.replaceAll('Exception: ', '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _userController.text.trim();
    final pass = _passController.text;

    setState(() => _loading = true);

    try {
      final result = await ApiService.login(user, pass);
      // Si el backend devuelve accessToken lo consideramos éxito
      if (result.containsKey('accessToken')) {
        // TODO: almacenar tokens si se desea
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else if (result['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        throw Exception('Login fallido');
      }
    } catch (e) {
      if (!mounted) return;
      final friendly = _friendlyError(e);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error al iniciar sesión'),
          content: Text(friendly),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F3), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App title / logo
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant, size: 56, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Leña Reserva',
                      style: theme.textTheme.titleLarge ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión para continuar',
                      style: theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 18),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _userController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              hintText: 'usuario@dominio.com',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingrese el usuario';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingrese la contraseña';
                              if (v.length < 4) return 'La contraseña es muy corta';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // placeholder: navegar a pantalla de recuperación si existe
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
