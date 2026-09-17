import 'package:flutter/material.dart';

import 'auth/auth_scope.dart';
import 'design/app_colors.dart';
import 'services/api_service.dart';

class ClientePage extends StatelessWidget {
  const ClientePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),

      // ============================================================
      // APP BAR
      // ============================================================
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

              if (!context.mounted) {
                return;
              }

              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      // ============================================================
      // CONTENIDO
      // ============================================================
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            // ======================================================
            // BIENVENIDA
            // ======================================================
            _WelcomeCard(name: auth.userName ?? 'Usuario'),

            const SizedBox(height: 28),

            // ======================================================
            // OPCIONES
            // ======================================================
            const Text(
              'Mis opciones',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // MIS RESERVAS
            // ======================================================
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

            // ======================================================
            // NUEVA RESERVA
            // ======================================================
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

            // ======================================================
            // DISPONIBILIDAD
            // ======================================================
            _OptionCard(
              icon: Icons.table_restaurant_outlined,
              title: 'Consultar disponibilidad',
              description:
                  'Consulta las mesas disponibles para una fecha y hora determinada.',
              onTap: () {
                debugPrint('CLIENTE - SE PRESIONÓ CONSULTAR DISPONIBILIDAD');

                _showAvailability(context);
              },
            ),

            const SizedBox(height: 28),

            // ======================================================
            // INFORMACIÓN
            // ======================================================
            const _InformationCard(),
          ],
        ),
      ),

      // ============================================================
      // BOTÓN FLOTANTE - ASISTENTE LEÑA
      // ============================================================
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

  // ==============================================================
  // MOSTRAR DISPONIBILIDAD
  // ==============================================================

  Future<void> _showAvailability(BuildContext context) async {
    final auth = AuthScope.of(context);

    if (!auth.isAuthenticated ||
        auth.accessToken == null ||
        auth.accessToken!.isEmpty) {
      if (!context.mounted) {
        return;
      }

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

// ==================================================================
// TARJETA DE BIENVENIDA
// ==================================================================

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF1EDEA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido $name',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292525),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desde aquí puedes administrar tus reservas.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// OPCIÓN
// ==================================================================

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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E2DF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// INFORMACIÓN
// ==================================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E0DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información para clientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Text(
                  'Puedes crear, consultar, modificar y cancelar '
                  'tus propias reservas. Las reservas de otros clientes '
                  'no son visibles para tu cuenta.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
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

// ==================================================================
// DIÁLOGO DE DISPONIBILIDAD
// ==================================================================

class _AvailabilityDialog extends StatefulWidget {
  const _AvailabilityDialog();

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> tables = const [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedDate = DateTime(now.year, now.month, now.day);

    selectedTime = const TimeOfDay(hour: 19, minute: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadAvailability();
    });
  }

  DateTime get selectedDateTime {
    final date = selectedDate!;

    final time = selectedTime ?? const TimeOfDay(hour: 19, minute: 0);

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ==============================================================
  // FECHA
  // ==============================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);
    });

    await _loadAvailability();
  }

  // ==============================================================
  // HORA
  // ==============================================================

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 19, minute: 0),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedTime = picked;
    });

    await _loadAvailability();
  }

  // ==============================================================
  // CONSULTAR DISPONIBILIDAD
  // ==============================================================

  Future<void> _loadAvailability() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = AuthScope.of(context);

      final token = auth.accessToken;

      if (!auth.isAuthenticated || token == null || token.isEmpty) {
        throw const ApiException(
          401,
          'La sesión ha expirado. Inicie sesión nuevamente.',
        );
      }

      final date = selectedDateTime;

      debugPrint(
        'CLIENTE - FECHA CONSULTADA: '
        '${date.toIso8601String()}',
      );

      final result = await ApiService.getAvailableTables(token, date: date);

      debugPrint('CLIENTE - MESAS RECIBIDAS: $result');

      if (!mounted) {
        return;
      }

      setState(() {
        tables = result;
        loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }

      if (exception.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();

        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: '/cliente',
        );

        return;
      }

      setState(() {
        loading = false;
        tables = [];
        error = exception.message;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        tables = [];
        error = 'No se pudo consultar la disponibilidad.';
      });

      debugPrint('CLIENTE - ERROR DISPONIBILIDAD: $exception');
    }
  }

  // ==============================================================
  // TEXTO FECHA
  // ==============================================================

  String _dateLabel() {
    if (selectedDate == null) {
      return 'Seleccionar fecha';
    }

    return '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';
  }

  // ==============================================================
  // TEXTO HORA
  // ==============================================================

  String _timeLabel() {
    if (selectedTime == null) {
      return 'Seleccionar hora';
    }

    return selectedTime!.format(context);
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(Icons.table_restaurant_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Consultar disponibilidad',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_dateLabel()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : _pickTime,
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(_timeLabel()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  // ==============================================================
  // CONTENIDO
  // ==============================================================

  Widget _buildContent() {
    if (loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadAvailability,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (tables.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No hay mesas disponibles para la fecha '
            'y hora seleccionadas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: tables.length,
        separatorBuilder: (_, __) {
          return const Divider(height: 1);
        },
        itemBuilder: (context, index) {
          final table = tables[index];

          final number = table['numero'] ?? table['id'] ?? '-';

          final capacity = table['capacidad'];

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.table_restaurant_outlined,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              'Mesa $number',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: capacity == null
                ? null
                : Text('Capacidad: $capacity personas'),
          );
        },
      ),
    );
  }
}
