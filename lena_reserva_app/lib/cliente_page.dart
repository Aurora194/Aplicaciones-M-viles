import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'auth/auth_scope.dart';
import 'design/app_colors.dart';
import 'services/api_service.dart';
import 'services/camera_service.dart';
import 'services/profile_photo_service.dart';

class ClientePage extends StatefulWidget {
  const ClientePage({super.key});

  @override
  State<ClientePage> createState() => _ClientePageState();
}

class _ClientePageState extends State<ClientePage> {
  Uint8List? _profilePhoto;
  bool _loadingPhoto = true;

  String _userPhotoKey = 'usuario';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilePhoto();
    });
  }

  // ============================================================
  // FOTO DE PERFIL
  // ============================================================

  Future<void> _loadProfilePhoto() async {
    if (!mounted) return;

    final auth = AuthScope.of(context);

    final userName = (auth.userName ?? 'usuario').trim();

    _userPhotoKey = userName.isEmpty ? 'usuario' : userName;

    final photo = await ProfilePhotoService.loadPhoto(userKey: _userPhotoKey);

    if (!mounted) return;

    setState(() {
      _profilePhoto = photo;
      _loadingPhoto = false;
    });
  }

  Future<void> _takeProfilePhoto() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tomar foto de perfil',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Leña Reserva necesita utilizar la cámara del dispositivo '
            'para tomar una foto de perfil. La fotografía se guardará '
            'localmente para este usuario.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true || !mounted) {
      return;
    }

    final result = await CameraService.takePhoto();

    if (!mounted) return;

    switch (result.status) {
      case CameraStatus.granted:
        if (result.file == null) {
          await _showMessage(
            title: 'No se pudo obtener la foto',
            message: 'La cámara no devolvió una imagen válida.',
          );
          return;
        }

        try {
          await ProfilePhotoService.savePhoto(
            userKey: _userPhotoKey,
            file: result.file!,
          );

          final photo = await ProfilePhotoService.loadPhoto(
            userKey: _userPhotoKey,
          );

          if (!mounted) return;

          setState(() {
            _profilePhoto = photo;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil guardada correctamente.'),
            ),
          );
        } catch (e) {
          debugPrint('CLIENTE - ERROR GUARDANDO FOTO: $e');

          await _showMessage(
            title: 'No se pudo guardar',
            message:
                'La foto fue tomada, pero no se pudo guardar '
                'en el dispositivo.',
          );
        }

        break;

      case CameraStatus.denied:
        await _showCameraDenied();
        break;

      case CameraStatus.permanentlyDenied:
        await _showCameraPermanentlyDenied();
        break;

      case CameraStatus.restricted:
        await _showMessage(
          title: 'Cámara restringida',
          message:
              'El sistema del dispositivo restringe el acceso '
              'a la cámara. Revisa los controles de privacidad '
              'o permisos del dispositivo.',
        );
        break;

      case CameraStatus.unavailable:
        await _showMessage(
          title: 'Cámara no disponible',
          message:
              'La cámara no está disponible en este dispositivo '
              'en este momento.',
        );
        break;

      case CameraStatus.cancelled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Captura cancelada.')));
        break;

      case CameraStatus.error:
        await _showMessage(
          title: 'Error de cámara',
          message:
              'No fue posible acceder a la cámara. '
              'Intenta nuevamente.',
        );
        break;
    }
  }

  Future<void> _showCameraDenied() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permiso de cámara denegado'),
          content: const Text(
            'No se concedió el permiso para utilizar la cámara. '
            'Puedes volver a intentarlo cuando quieras.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCameraPermanentlyDenied() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permiso bloqueado'),
          content: const Text(
            'El acceso a la cámara está bloqueado para esta '
            'aplicación. Para volver a utilizarla, debes '
            'habilitar el permiso desde los ajustes del dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await CameraService.openSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMessage({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),

      appBar: AppBar(
        title: const Text(
          'Cliente',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await auth.signOut();

              if (!context.mounted) return;

              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            _WelcomeCard(
              name: auth.userName ?? 'Usuario',
              photo: _profilePhoto,
              loadingPhoto: _loadingPhoto,
              onTakePhoto: _takeProfilePhoto,
            ),

            const SizedBox(height: 28),

            const Text(
              'Mis opciones',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            _OptionCard(
              icon: Icons.calendar_month_outlined,
              title: 'Ver mis reservas',
              description:
                  'Consulta tus reservas pendientes, confirmadas y canceladas.',
              onTap: () {
                Navigator.pushNamed(context, '/app/reservas');
              },
            ),

            const SizedBox(height: 14),

            _OptionCard(
              icon: Icons.add_circle_outline,
              title: 'Nueva reserva',
              description:
                  'Crea una nueva reserva seleccionando fecha, hora, personas y mesa.',
              onTap: () {
                Navigator.pushNamed(context, '/app/reservas/nueva');
              },
            ),

            const SizedBox(height: 14),

            _OptionCard(
              icon: Icons.table_restaurant_outlined,
              title: 'Consultar disponibilidad',
              description:
                  'Selecciona una fecha y hora para consultar las mesas disponibles.',
              onTap: () {
                debugPrint('CLIENTE - SE PRESIONÓ CONSULTAR DISPONIBILIDAD');

                _showAvailability(context);
              },
            ),

            const SizedBox(height: 28),

            const _InformationCard(),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cliente_ai_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        onPressed: () {
          Navigator.pushNamed(context, '/app/ai');
        },
        icon: const Icon(Icons.auto_awesome_rounded, size: 21),
        label: const Text(
          'Asistente Leña',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showAvailability(BuildContext context) async {
    final auth = AuthScope.of(context);

    if (!auth.isAuthenticated ||
        auth.accessToken == null ||
        auth.accessToken!.isEmpty) {
      if (!context.mounted) return;

      Navigator.pushReplacementNamed(context, '/login', arguments: '/cliente');

      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AvailabilityDialog(),
    );
  }
}

// ============================================================
// TARJETA DE BIENVENIDA
// ============================================================

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.photo,
    required this.loadingPhoto,
    required this.onTakePhoto,
  });

  final String name;
  final Uint8List? photo;
  final bool loadingPhoto;
  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
                child: ClipOval(
                  child: loadingPhoto
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : photo != null
                      ? Image.memory(
                          photo!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person_outline,
                          size: 36,
                          color: AppColors.primary,
                        ),
                ),
              ),

              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    onTap: onTakePhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),

                const SizedBox(height: 4),

                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Gestiona tus reservas en Leña.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OPCIÓN
// ============================================================

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INFORMACIÓN
// ============================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 6),

                Text(
                  'Puedes consultar tus reservas, crear una nueva '
                  'reserva y verificar la disponibilidad de mesas.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIÁLOGO DE DISPONIBILIDAD
// ============================================================

class _AvailabilityDialog extends StatefulWidget {
  const _AvailabilityDialog();

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool loading = false;

  String? errorMessage;

  List<dynamic> mesas = [];

  // ============================================================
  // FECHA
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      selectedDate = DateTime(result.year, result.month, result.day);

      errorMessage = null;
      mesas = [];
    });
  }

  // ============================================================
  // HORA
  // ============================================================

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 19, minute: 0),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      selectedTime = result;

      errorMessage = null;
      mesas = [];
    });
  }

  // ============================================================
  // CONSULTAR
  // ============================================================

  Future<void> _loadAvailability() async {
    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorMessage =
            'Selecciona una fecha y una hora para consultar la disponibilidad.';
      });

      return;
    }

    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'La sesión no es válida.';
        loading = false;
      });

      return;
    }

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    debugPrint('========================================');
    debugPrint('CLIENTE - CONSULTA DE DISPONIBILIDAD');
    debugPrint('Fecha: ${_formatDate(selectedDate!)}');
    debugPrint('Hora: ${_formatTime(selectedTime!)}');
    debugPrint('DateTime: $dateTime');
    debugPrint('========================================');

    setState(() {
      loading = true;
      errorMessage = null;
      mesas = [];
    });

    try {
      /*
       * IMPORTANTE:
       *
       * Esta consulta NO utiliza AIPage.
       * Se comunica directamente con el backend de mesas
       * mediante ApiService.getAvailableTables().
       */
      final result = await ApiService.getAvailableTables(token, date: dateTime);

      if (!mounted) return;

      setState(() {
        mesas = result;
        loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;

      if (exception.statusCode == 401) {
        await auth.signOut();

        if (!mounted) return;

        Navigator.of(context).pop();

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);

        return;
      }

      setState(() {
        loading = false;
        errorMessage = exception.message;
      });
    } catch (error) {
      debugPrint('CLIENTE - ERROR DISPONIBILIDAD: $error');

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
            'No fue posible consultar la disponibilidad. '
            'Intenta nuevamente.';
      });
    }
  }

  // ============================================================
  // FORMATO FECHA
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // FORMATO HORA
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ============================================================
  // NOMBRE DE MESA
  // ============================================================

  String _getMesaNumero(dynamic mesa) {
    if (mesa is Map) {
      return '${mesa['numero'] ?? mesa['nombre'] ?? 'Mesa'}';
    }

    return 'Mesa';
  }

  // ============================================================
  // CAPACIDAD
  // ============================================================

  String _getMesaCapacidad(dynamic mesa) {
    if (mesa is Map) {
      return '${mesa['capacidad'] ?? '-'} personas';
    }

    return '- personas';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    final hasTime = selectedTime != null;
    final canSearch = hasDate && hasTime;

    return AlertDialog(
      title: const Text(
        'Consultar disponibilidad',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),

      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // FECHA
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    hasDate ? _formatDate(selectedDate!) : 'Seleccionar fecha',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // HORA
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _pickTime,
                  icon: const Icon(Icons.access_time_outlined, size: 18),
                  label: Text(
                    hasTime ? _formatTime(selectedTime!) : 'Seleccionar hora',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // BOTÓN CONSULTAR
              // ==================================================
              if (canSearch)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : _loadAvailability,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      loading ? 'Consultando...' : 'Consultar disponibilidad',
                    ),
                  ),
                ),

              if (!canSearch) ...[
                const SizedBox(height: 8),

                const Text(
                  'Selecciona una fecha y una hora para consultar las mesas disponibles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],

              const SizedBox(height: 18),

              // ==================================================
              // ERROR
              // ==================================================
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: Colors.redAccent,
                      ),

                      const SizedBox(height: 10),

                      Text(errorMessage!, textAlign: TextAlign.center),

                      const SizedBox(height: 12),

                      if (canSearch)
                        OutlinedButton.icon(
                          onPressed: loading ? null : _loadAvailability,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                    ],
                  ),
                )
              // ==================================================
              // CARGANDO
              // ==================================================
              else if (loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              // ==================================================
              // RESULTADOS
              // ==================================================
              else if (canSearch && mesas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        size: 42,
                        color: Colors.black38,
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No hay mesas disponibles para la fecha y hora seleccionadas.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (mesas.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mesas.length} mesa(s) disponible(s)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 10),

                    ...mesas.map((mesa) => _buildTableItem(mesa)),
                  ],
                ),
            ],
          ),
        ),
      ),

      // ==========================================================
      // CERRAR
      // ==========================================================
      actions: [
        TextButton(
          onPressed: loading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  // ============================================================
  // ELEMENTO DE MESA
  // ============================================================

  Widget _buildTableItem(dynamic mesa) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.table_restaurant, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMesaNumero(mesa),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 3),

                Text(
                  _getMesaCapacidad(mesa),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle_outline, color: Colors.green),
        ],
      ),
    );
  }
}
