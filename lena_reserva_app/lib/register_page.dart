import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'state/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ApiService.registerUser(
        nombre: name.text.trim(),
        apellido: lastName.text.trim(),
        correo: email.text.trim(),
        telefono: phone.text.trim(),
        password: password.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro exitoso. Ingrese con sus credenciales.')));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? requiredValue(String? value, String label) => value == null || value.trim().isEmpty ? '$label es obligatorio.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF9F7F6),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavButton(label: 'Login', onPressed: () => Navigator.pushReplacementNamed(context, '/login')),
              _NavButton(label: 'Registro', active: true, onPressed: () {}),
              _NavButton(
                label: 'Reservas',
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
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 7,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const Icon(Icons.person_add_alt_1, size: 48, color: Color(0xFFAA0000)),
                        const SizedBox(height: 12),
                        const Text('Crear cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 22),
                        TextFormField(controller: name, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Nombre'), validator: (value) => requiredValue(value, 'El nombre')),
                        const SizedBox(height: 12),
                        TextFormField(controller: lastName, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Apellido'), validator: (value) => requiredValue(value, 'El apellido')),
                        const SizedBox(height: 12),
                        TextFormField(controller: email, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Correo'), validator: (value) => value != null && value.contains('@') ? null : 'Ingrese un correo válido.'),
                        const SizedBox(height: 12),
                        TextFormField(controller: phone, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), labelText: 'Teléfono'), validator: (value) => requiredValue(value, 'El teléfono')),
                        const SizedBox(height: 12),
                        TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), labelText: 'Contraseña'), validator: (value) => value != null && value.length >= 4 ? null : 'Mínimo 4 caracteres.'),
                        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                        const SizedBox(height: 24),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: saving ? null : submit, child: saving ? const CircularProgressIndicator() : const Text('Crear cuenta'))),
                      ],
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
  const _NavButton({required this.label, required this.onPressed, this.active = false});

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: active ? Colors.black87 : Theme.of(context).colorScheme.primary,
            backgroundColor: active ? Colors.black12 : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            textStyle: TextStyle(fontSize: 15, fontWeight: active ? FontWeight.bold : FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label),
        ),
      );
}
