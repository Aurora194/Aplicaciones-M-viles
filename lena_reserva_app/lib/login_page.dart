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
        // ------------------------------------------------------
        // ROL
        // ------------------------------------------------------

        final rawRole = usuario['rol']?.toString();

        if (rawRole != null && rawRole.trim().isNotEmpty) {
          role = rawRole.trim().toUpperCase();
        }

        // ------------------------------------------------------
        // ID
        // ------------------------------------------------------

        final rawId = usuario['id'];

        if (rawId is num) {
          userId = rawId.toInt();
        } else {
          userId = int.tryParse(rawId?.toString() ?? '');
        }

        // ------------------------------------------------------
        // NOMBRE
        // ------------------------------------------------------

        userName = usuario['nombre']?.toString();

        // ------------------------------------------------------
        // APELLIDO
        // ------------------------------------------------------

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

      // ========================================================
      // ERROR 401
      // ========================================================

      if (exception.statusCode == 401) {
        message = 'Correo o contraseña incorrectos.';
      }
      // ========================================================
      // ERROR 403
      // ========================================================
      else if (exception.statusCode == 403) {
        message = 'No tienes permiso para acceder con esta cuenta.';
      }
      // ========================================================
      // ERROR 422
      // ========================================================
      else if (exception.statusCode == 422) {
        message = exception.message.isNotEmpty
            ? exception.message
            : 'Verifica los datos ingresados.';
      }
      // ========================================================
      // ERROR 500
      // ========================================================
      else if (exception.statusCode >= 500) {
        message =
            'El servidor no está disponible en este momento. '
            'Inténtalo nuevamente.';
      }
      // ========================================================
      // OTROS
      // ========================================================
      else {
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
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F5),

      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
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

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: EdgeInsets.symmetric(
              horizontal: 22,
              vertical: keyboardVisible ? 12 : 24,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),

              child: Card(
                elevation: keyboardVisible ? 3 : 7,
                shadowColor: Colors.black.withValues(alpha: 0.12),

                color: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),

                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    keyboardVisible ? 22 : 32,
                    24,
                    keyboardVisible ? 20 : 28,
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
                          width: keyboardVisible ? 62 : 76,
                          height: keyboardVisible ? 62 : 76,

                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),

                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.primary,
                            size: keyboardVisible ? 31 : 38,
                          ),
                        ),

                        SizedBox(height: keyboardVisible ? 10 : 18),

                        // ==================================================
                        // TÍTULO
                        // ==================================================
                        const Text(
                          'Leña Reserva App',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: Color(0xFF5F5F5F),
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: Color(0xFF858585),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: keyboardVisible ? 18 : 26),

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

                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',

                            hintText: 'ejemplo@correo.com',

                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),

                            filled: true,

                            fillColor: const Color(0xFFFCFCFC),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                          ),

                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 15),

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

                          decoration: InputDecoration(
                            labelText: 'Contraseña',

                            hintText: 'Ingrese su contraseña',

                            prefixIcon: const Icon(Icons.lock_outline_rounded),

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

                            filled: true,

                            fillColor: const Color(0xFFFCFCFC),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red),
                            ),

                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                          ),

                          validator: _validatePassword,
                        ),

                        // ==================================================
                        // ERROR
                        // ==================================================
                        if (error != null) ...[
                          const SizedBox(height: 13),

                          Container(
                            width: double.infinity,

                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),

                              borderRadius: BorderRadius.circular(10),

                              border: Border.all(
                                color: const Color(0xFFF4C5CA),
                              ),
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFB42318),
                                  size: 20,
                                ),

                                const SizedBox(width: 9),

                                Expanded(
                                  child: Text(
                                    error!,

                                    style: const TextStyle(
                                      color: Color(0xFFB42318),
                                      fontSize: 12.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: keyboardVisible ? 17 : 23),

                        // ==================================================
                        // BOTÓN INGRESAR
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 50,

                          child: ElevatedButton(
                            onPressed: loading ? null : submit,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,

                              foregroundColor: Colors.white,

                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.55),

                              disabledForegroundColor: Colors.white,

                              elevation: 0,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),

                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,

                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
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
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // RECUPERAR CONTRASEÑA
                        // ==================================================
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

                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,

                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                          ),

                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // ==================================================
                        // REGISTRO
                        // ==================================================
                        const SizedBox(height: 2),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            const Text(
                              '¿No tienes una cuenta?',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 12.5,
                              ),
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
                                  fontSize: 12.5,
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
              ),
            ),
          ),
        ),
      ),
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
