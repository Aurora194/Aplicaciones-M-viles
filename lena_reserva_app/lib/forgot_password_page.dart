import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  bool loading = false;
  String? error;
  String? success;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    if (loading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
      success = null;
    });

    try {
      final result = await ApiService.forgotPassword(
        emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        success =
            result['message']?.toString() ??
            'Si el correo está registrado, recibirá un código.';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordPage(correo: emailController.text.trim()),
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = exception.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'No se pudo enviar el código de recuperación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F6),
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          '¿Olvidaste tu contraseña?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Ingresa tu correo electrónico y te enviaremos un código de recuperación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),

                        const SizedBox(height: 26),

                        TextFormField(
                          controller: emailController,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Ingrese su correo.';
                            }

                            if (!email.contains('@')) {
                              return 'Ingrese un correo válido.';
                            }

                            return null;
                          },
                        ),

                        if (error != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(message: error!, isError: true),
                        ],

                        if (success != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(message: success!, isError: false),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : sendCode,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enviar código',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.correo});

  final String correo;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final formKey = GlobalKey<FormState>();

  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  String? error;
  String? success;

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (loading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
      success = null;
    });

    try {
      final result = await ApiService.resetPassword(
        correo: widget.correo,
        codigo: codeController.text.trim(),
        nuevaPassword: passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        success =
            result['message']?.toString() ??
            'Contraseña actualizada correctamente.';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (exception) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = exception.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'No se pudo actualizar la contraseña.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F6),
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Verificar código',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Ingresa el código enviado a ${widget.correo}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),

                        const SizedBox(height: 24),

                        TextFormField(
                          controller: codeController,
                          enabled: !loading,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Código de recuperación',
                            prefixIcon: Icon(Icons.pin_outlined),
                            counterText: '',
                          ),
                          validator: (value) {
                            final code = value?.trim() ?? '';

                            if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                              return 'Ingrese el código de 6 dígitos.';
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
                            labelText: 'Nueva contraseña',
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
                              return 'Mínimo 4 caracteres.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmController,
                          enabled: !loading,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscureConfirm = !obscureConfirm;
                                      });
                                    },
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != passwordController.text) {
                              return 'Las contraseñas no coinciden.';
                            }

                            return null;
                          },
                        ),

                        if (error != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(message: error!, isError: true),
                        ],

                        if (success != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(message: success!, isError: false),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading ? null : resetPassword,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Cambiar contraseña',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Theme.of(context).colorScheme.error : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }
}
