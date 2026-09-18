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
            behavior: SnackBarBehavior.floating,
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

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> submit() async {
    if (loading) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final auth = AuthScope.of(context);

    try {
      // ========================================================
      // 1. LOGIN CONTRA EL BACKEND
      // ========================================================

      final result = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      debugPrint('========================================');
      debugPrint('LOGIN - RESPUESTA DEL BACKEND');
      debugPrint('$result');
      debugPrint('========================================');

      final accessToken = result['accessToken']?.toString();
      final refreshToken = result['refreshToken']?.toString();

      // ========================================================
      // 2. VALIDAR TOKEN
      // ========================================================

      if (accessToken == null || accessToken.isEmpty || accessToken == 'null') {
        if (!mounted) return;

        setState(() {
          error =
              'El servidor respondió correctamente, pero no devolvió '
              'el token de acceso.';
          loading = false;
        });

        return;
      }

      // ========================================================
      // 3. OBTENER INFORMACIÓN DEL USUARIO
      // ========================================================

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

      debugPrint('========================================');
      debugPrint('USUARIO RECIBIDO');
      debugPrint('Usuario: $usuario');
      debugPrint('ID: $userId');
      debugPrint('Rol: $role');
      debugPrint('Nombre: $userName');
      debugPrint('Apellido: $userLastName');
      debugPrint('========================================');

      // ========================================================
      // 4. GUARDAR SESIÓN
      // ========================================================

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

      // ========================================================
      // 5. DETERMINAR DESTINO
      // ========================================================

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

      // ========================================================
      // 6. NAVEGAR
      // ========================================================

      try {
        await Navigator.pushReplacementNamed(context, destination);
      } catch (e) {
        if (!mounted) return;

        debugPrint('Error de navegación después del login: $e');

        setState(() {
          error =
              'El inicio de sesión fue correcto, pero no se pudo '
              'abrir la pantalla "$destination".\n$e';
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

      String message;

      if (exception.statusCode == 401) {
        message = 'Correo o contraseña incorrectos.';
      } else if (exception.statusCode == 403) {
        message = 'No tienes permiso para acceder con esta cuenta.';
      } else if (exception.statusCode == 422) {
        message = exception.message.isNotEmpty
            ? exception.message
            : 'Verifica los datos ingresados.';
      } else if (exception.statusCode >= 500) {
        message =
            'El servidor no está disponible en este momento. '
            'Inténtalo nuevamente.';
      } else {
        message = exception.message;
      }

      setState(() {
        error = message;
        loading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      debugPrint('========================================');
      debugPrint('ERROR INESPERADO EN LOGIN');
      debugPrint('$e');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('========================================');

      setState(() {
        error =
            'No fue posible conectarse con el servidor. '
            'Verifica tu conexión e inténtalo nuevamente.';
        loading = false;
      });

      return;
    }
  }

  // ============================================================
  // ABRIR RESERVAS
  // ============================================================

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

  // ============================================================
  // VALIDAR CORREO
  // ============================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingrese su correo electrónico.';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Ingrese un correo válido.';
    }

    return null;
  }

  // ============================================================
  // VALIDAR CONTRASEÑA
  // ============================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su contraseña.';
    }

    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres.';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final keyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F4),

      resizeToAvoidBottomInset: true,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.transparent,

        toolbarHeight: 58,

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavButton(label: 'Login', active: true, onPressed: () {}),

            _NavButton(
              label: 'Registro',
              onPressed: loading
                  ? () {}
                  : () {
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

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            /*
             * Cuando aparece el teclado, Flutter reduce
             * automáticamente el área disponible gracias a
             * resizeToAvoidBottomInset.
             *
             * La Card se coloca dentro de ESA área.
             *
             * El teclado queda debajo de esta zona y nunca
             * se dibuja encima de la Card.
             */

            final availableHeight = constraints.maxHeight;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              padding: EdgeInsets.only(
                left: 18,
                right: 18,

                top: keyboardVisible ? 8 : 20,

                bottom: keyboardVisible ? 12 : 24,
              ),

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight - (keyboardVisible ? 20 : 44),
                ),

                child: Align(
                  alignment: keyboardVisible
                      ? Alignment.topCenter
                      : Alignment.center,

                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),

                    child: _buildLoginCard(keyboardVisible),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE LOGIN
  // ============================================================

  Widget _buildLoginCard(bool keyboardVisible) {
    return Card(
      margin: EdgeInsets.zero,

      elevation: keyboardVisible ? 5 : 9,

      shadowColor: Colors.black.withValues(alpha: 0.14),

      color: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          keyboardVisible ? 18 : 30,
          24,
          keyboardVisible ? 18 : 26,
        ),

        child: Form(
          key: formKey,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ==================================================
              // LOGO
              // ==================================================
              Container(
                width: keyboardVisible ? 56 : 72,
                height: keyboardVisible ? 56 : 72,

                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.restaurant_rounded,

                  color: AppColors.primary,

                  size: keyboardVisible ? 29 : 36,
                ),
              ),

              SizedBox(height: keyboardVisible ? 7 : 14),

              // ==================================================
              // TÍTULO
              // ==================================================
              const Text(
                'Leña Reserva App',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFF4F4F4F),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Inicia sesión para continuar',

                textAlign: TextAlign.center,

                style: TextStyle(color: Color(0xFF888888), fontSize: 12.5),
              ),

              SizedBox(height: keyboardVisible ? 13 : 22),

              // ==================================================
              // CORREO
              // ==================================================
              TextFormField(
                controller: emailController,

                keyboardType: TextInputType.emailAddress,

                textInputAction: TextInputAction.next,

                enabled: !loading,

                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],

                onChanged: (_) {
                  if (error != null) {
                    setState(() {
                      error = null;
                    });
                  }
                },

                decoration: _inputDecoration(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  icon: Icons.person_outline_rounded,
                ),

                validator: _validateEmail,
              ),

              SizedBox(height: keyboardVisible ? 10 : 14),

              // ==================================================
              // CONTRASEÑA
              // ==================================================
              TextFormField(
                controller: passwordController,

                enabled: !loading,

                obscureText: obscurePassword,

                textInputAction: TextInputAction.done,

                autofillHints: const [AutofillHints.password],

                onFieldSubmitted: (_) {
                  if (!loading) {
                    submit();
                  }
                },

                onChanged: (_) {
                  if (error != null) {
                    setState(() {
                      error = null;
                    });
                  }
                },

                decoration: _inputDecoration(
                  label: 'Contraseña',
                  hint: 'Ingrese su contraseña',
                  icon: Icons.lock_outline_rounded,

                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',

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

                validator: _validatePassword,
              ),

              // ==================================================
              // ERROR
              // ==================================================
              if (error != null) ...[
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),

                    borderRadius: BorderRadius.circular(10),

                    border: Border.all(color: const Color(0xFFF4C5CA)),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.error_outline_rounded,

                        color: Color(0xFFB42318),

                        size: 19,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          error!,

                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: keyboardVisible ? 11 : 20),

              // ==================================================
              // BOTÓN INGRESAR
              // ==================================================
              SizedBox(
                width: double.infinity,

                height: keyboardVisible ? 46 : 50,

                child: ElevatedButton(
                  onPressed: loading ? null : submit,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.55,
                    ),

                    disabledForegroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          width: 21,
                          height: 21,

                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Icon(Icons.login_rounded, size: 20),

                            SizedBox(width: 8),

                            Text(
                              'Ingresar',

                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: keyboardVisible ? 3 : 7),

              // ==================================================
              // OLVIDASTE TU CONTRASEÑA
              // ==================================================
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },

                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  minimumSize: Size.zero,

                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                child: const Text(
                  '¿Olvidaste tu contraseña?',

                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

              // ==================================================
              // REGISTRO
              // ==================================================
              const SizedBox(height: 1),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text(
                    '¿No tienes una cuenta?',

                    style: TextStyle(color: Color(0xFF777777), fontSize: 12),
                  ),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.pushNamed(context, '/registro');
                          },

                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),

                      minimumSize: Size.zero,

                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),

                    child: const Text(
                      'Crear cuenta',

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DECORACIÓN DE CAMPOS
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,

      hintText: hint,

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: const Color(0xFFFBFBFB),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: BorderSide(color: AppColors.primary, width: 1.7),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),

        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ==================================================================
// BOTONES DEL MENÚ SUPERIOR
// ==================================================================

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

          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),

          minimumSize: Size.zero,

          tapTargetSize: MaterialTapTargetSize.shrinkWrap,

          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
          ),

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),

        child: Text(label),
      ),
    );
  }
}
