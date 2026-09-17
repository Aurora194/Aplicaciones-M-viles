import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'models/reservation.dart';
import 'services/api_service.dart';
import '../services/notification_service.dart';
import 'auth/auth_scope.dart';

enum ReservationLoadState { loading, empty, error, success }

/// ===============================================================
/// ZONA HORARIA DE ECUADOR
/// ===============================================================
///
/// Ecuador continental utiliza UTC-5 y no tiene horario de verano.
///
/// Regla de esta aplicación:
///
///   UI Flutter  -> Ecuador UTC-5
///   Backend     -> UTC
///   Base de datos -> UTC
///
/// Ejemplo:
///
///   Ecuador: 17/09/2026 20:00
///   UTC:     18/09/2026 01:00
///
/// Cuando el backend devuelve:
///
///   2026-09-18T01:00:00.000Z
///
/// Flutter muestra:
///
///   17/09/2026 20:00
/// ===============================================================

const Duration _ecuadorUtcOffset = Duration(hours: -5);

/// Obtiene la fecha y hora actual de Ecuador independientemente
/// de la zona horaria configurada en el dispositivo/emulador.
DateTime ecuadorNow() {
  final utcNow = DateTime.now().toUtc();

  final ecuador = utcNow.add(_ecuadorUtcOffset);

  return DateTime(
    ecuador.year,
    ecuador.month,
    ecuador.day,
    ecuador.hour,
    ecuador.minute,
    ecuador.second,
    ecuador.millisecond,
    ecuador.microsecond,
  );
}

/// Obtiene solamente la fecha actual de Ecuador.
DateTime ecuadorToday() {
  final now = ecuadorNow();

  return DateTime(now.year, now.month, now.day);
}

/// Convierte una fecha/hora que representa Ecuador UTC-5 a UTC.
///
/// Ejemplo:
/// 17/09/2026 20:00 Ecuador
/// -> 18/09/2026 01:00 UTC
DateTime ecuadorToUtc(DateTime ecuadorDateTime) {
  return DateTime.utc(
    ecuadorDateTime.year,
    ecuadorDateTime.month,
    ecuadorDateTime.day,
    ecuadorDateTime.hour + 5,
    ecuadorDateTime.minute,
    ecuadorDateTime.second,
    ecuadorDateTime.millisecond,
    ecuadorDateTime.microsecond,
  );
}

/// Convierte una fecha/hora UTC recibida del backend a Ecuador UTC-5.
///
/// Ejemplo:
/// 18/09/2026 01:00 UTC
/// -> 17/09/2026 20:00 Ecuador
DateTime utcToEcuador(DateTime dateTime) {
  final utc = dateTime.toUtc();

  final ecuador = utc.add(_ecuadorUtcOffset);

  return DateTime(
    ecuador.year,
    ecuador.month,
    ecuador.day,
    ecuador.hour,
    ecuador.minute,
    ecuador.second,
    ecuador.millisecond,
    ecuador.microsecond,
  );
}

/// Combina fecha + hora seleccionadas por el usuario.
///
/// IMPORTANTE:
/// El resultado representa una hora de Ecuador, no UTC.
DateTime buildEcuadorDateTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  ReservationLoadState state = ReservationLoadState.loading;

  List<Reservation> reservations = const [];

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = AuthScope.of(context);

      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: '/cliente',
        );
        return;
      }

      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      state = ReservationLoadState.loading;
      errorMessage = null;
    });

    try {
      final auth = AuthScope.of(context);
      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      final result = await ApiService.getReservations(token);

      if (!mounted) return;

      setState(() {
        reservations = result;
        state = result.isEmpty
            ? ReservationLoadState.empty
            : ReservationLoadState.success;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        state = ReservationLoadState.error;
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        state = ReservationLoadState.error;
        errorMessage = 'Error al cargar las reservas: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthScope.of(context).userRole == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reservation_ai_fab',
        onPressed: () {
          Navigator.pushNamed(context, '/app/ai');
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Asistente IA'),
      ),

      appBar: AppBar(
        title: const Text(
          'Reservas',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Filtrar reservas',
              onPressed: () {},
              icon: const Icon(Icons.filter_list_outlined),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthScope.of(context).signOut();

              if (!context.mounted) return;

              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: switch (state) {
        ReservationLoadState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ReservationLoadState.empty => _buildEmptyState(isAdmin),
        ReservationLoadState.error => _ErrorView(
          message: errorMessage ?? 'Error desconocido.',
          onRetry: _load,
        ),
        ReservationLoadState.success => _buildSuccessState(isAdmin),
      },
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          const Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Reservas',
                  value: '0',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _SummaryTile(
                  label: 'Confirmadas',
                  value: '0',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _NewReservationButton(),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            const _ManageTablesButton(),
          ],
          const SizedBox(height: 80),
          const Center(child: Text('No hay reservas registradas.')),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isAdmin) {
    final confirmedCount = reservations
        .where((reservation) => reservation.status == 'CONFIRMADA')
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Reservas',
                  value: '${reservations.length}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryTile(
                  label: 'Confirmadas',
                  value: '$confirmedCount',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _NewReservationButton(),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            const _ManageTablesButton(),
          ],
          const SizedBox(height: 24),
          ...reservations.map(
            (reservation) => _ReservationCard(
              item: reservation,
              onTap: () async {
                final auth = AuthScope.of(context);

                await Navigator.pushNamed(
                  context,
                  '/app/reservas/${reservation.id}',
                );

                if (!mounted) return;

                if (auth.isAuthenticated) {
                  await _load();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E1DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewReservationButton extends StatelessWidget {
  const _NewReservationButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/app/reservas/nueva');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva reserva'),
      ),
    );
  }
}

class _ManageTablesButton extends StatelessWidget {
  const _ManageTablesButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/app/mesas');
        },
        icon: const Icon(Icons.table_restaurant),
        label: const Text('Gestionar mesas'),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.item, required this.onTap});

  final Reservation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// El backend devuelve UTC.
    /// Aquí convertimos a Ecuador para mostrar al usuario.
    final ecuadorDate = utcToEcuador(item.date);

    final statusColor = item.status == 'CONFIRMADA'
        ? AppColors.success
        : item.status == 'CANCELADA'
        ? AppColors.error
        : AppColors.warning;

    final statusLabel = item.status == 'CONFIRMADA'
        ? 'Confirmada'
        : item.status == 'CANCELADA'
        ? 'Cancelada'
        : 'Pendiente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mesa ${item.tableNumber ?? item.tableId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                AuthScope.of(context).userRole == 'ADMIN'
                    ? item.clientName ?? 'Reserva de mesa'
                    : 'Mi reserva',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _ReservationMeta(
                    icon: Icons.calendar_today_outlined,
                    text:
                        '${ecuadorDate.day} ${_month(ecuadorDate.month)} ${ecuadorDate.year}',
                  ),
                  _ReservationMeta(
                    icon: Icons.access_time_outlined,
                    text:
                        '${ecuadorDate.hour.toString().padLeft(2, '0')}:${ecuadorDate.minute.toString().padLeft(2, '0')}',
                  ),
                  _ReservationMeta(
                    icon: Icons.people_alt_outlined,
                    text: '${item.people} personas',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _month(int month) {
    return const [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ][month - 1];
  }
}

class _ReservationMeta extends StatelessWidget {
  const _ReservationMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primaryLight),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class ReservationDetailPage extends StatefulWidget {
  const ReservationDetailPage({super.key, required this.id});

  final int id;

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  late Future<Reservation> request;

  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (initialized) return;

    final token = AuthScope.of(context).accessToken;

    if (token == null || token.isEmpty) {
      request = Future.error(const ApiException(401, 'Sesión no disponible.'));
    } else {
      request = ApiService.getReservation(token, widget.id);
    }

    initialized = true;
  }

  Future<void> _changeStatus(Reservation item, String status) async {
    final action = status == 'CONFIRMADA' ? 'confirmar' : 'cancelar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == 'CONFIRMADA' ? 'Confirmar reserva' : 'Cancelar reserva',
          ),
          content: Text('¿Desea $action la reserva #${item.id}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text('Sí, $action'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final token = AuthScope.of(context).accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'Sesión no disponible.');
      }

      await ApiService.updateReservationStatus(
        token: token,
        id: item.id,
        status: status,
      );

      if (status == 'CANCELADA') {
        await NotificationService.cancelReservationNotification(item.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'CONFIRMADA'
                ? 'Reserva confirmada.'
                : 'Reserva cancelada.',
          ),
        ),
      );

      setState(() {
        request = ApiService.getReservation(token, widget.id);
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _edit(Reservation item) async {
    final peopleController = TextEditingController(
      text: item.people.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final pageContext = context;
    final auth = AuthScope.of(context);

    /// El backend entrega UTC.
    /// Para editar mostramos Ecuador.
    DateTime editDate = utcToEcuador(item.date);

    TimeOfDay editTime = TimeOfDay.fromDateTime(editDate);

    bool savingEdit = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final todayEcuador = ecuadorToday();

            final initialPickerDate = editDate.isBefore(todayEcuador)
                ? todayEcuador
                : editDate;

            return AlertDialog(
              title: const Text('Editar reserva'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: peopleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de personas',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');

                        if (number == null || number < 1 || number > 20) {
                          return 'Ingrese entre 1 y 20 personas.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              '${editDate.day}/${editDate.month}/${editDate.year}',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                firstDate: todayEcuador,
                                lastDate: todayEcuador.add(
                                  const Duration(days: 365),
                                ),
                                initialDate: initialPickerDate,
                              );

                              if (picked == null || !dialogContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                editDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  editTime.hour,
                                  editTime.minute,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_outlined),
                            label: Text(editTime.format(dialogContext)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: editTime,
                              );

                              if (picked == null || !dialogContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                editTime = picked;

                                editDate = DateTime(
                                  editDate.year,
                                  editDate.month,
                                  editDate.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: savingEdit
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            savingEdit = true;
                          });

                          try {
                            final token = auth.accessToken;

                            if (token == null || token.isEmpty) {
                              throw const ApiException(
                                401,
                                'Sesión no disponible.',
                              );
                            }

                            /// editDate/editTime representan
                            /// Ecuador.
                            final ecuadorDate = buildEcuadorDateTime(
                              editDate,
                              editTime,
                            );

                            /// Convertimos Ecuador -> UTC.
                            final utcDate = ecuadorToUtc(ecuadorDate);

                            debugPrint(
                              'EDITAR - ECUADOR: '
                              '$ecuadorDate',
                            );

                            debugPrint(
                              'EDITAR - UTC: '
                              '${utcDate.toIso8601String()}',
                            );

                            await ApiService.updateReservation(
                              token: token,
                              id: item.id,
                              date: utcDate,
                              people: int.parse(peopleController.text),
                              userId: auth.userId ?? 0,
                              tableId: item.tableId,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } on ApiException catch (error) {
                            if (pageContext.mounted) {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            }

                            if (dialogContext.mounted) {
                              setDialogState(() {
                                savingEdit = false;
                              });
                            }
                          }
                        },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    peopleController.dispose();

    if (result == true && mounted) {
      final token = AuthScope.of(context).accessToken;

      if (token == null || token.isEmpty) {
        return;
      }

      setState(() {
        request = ApiService.getReservation(token, widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de reserva')),
      body: FutureBuilder<Reservation>(
        future: request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const _ErrorView(message: 'No se pudo cargar el detalle.');
          }

          final item = snapshot.data!;

          /// UTC -> Ecuador para mostrar.
          final ecuadorDate = utcToEcuador(item.date);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Detalle de reserva #${item.id}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la reserva',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: Icons.table_restaurant_outlined,
                        label: 'Mesa',
                        value: 'Mesa ${item.tableNumber ?? item.tableId}',
                      ),
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Fecha',
                        value:
                            '${ecuadorDate.day} ${_month(ecuadorDate.month)} ${ecuadorDate.year}',
                      ),
                      _DetailRow(
                        icon: Icons.access_time_outlined,
                        label: 'Hora',
                        value:
                            '${ecuadorDate.hour.toString().padLeft(2, '0')}:${ecuadorDate.minute.toString().padLeft(2, '0')}',
                      ),
                      _DetailRow(
                        icon: Icons.people_alt_outlined,
                        label: 'Personas',
                        value: '${item.people} personas',
                      ),
                      _DetailRow(
                        icon: Icons.info_outline,
                        label: 'Estado',
                        value: item.status,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _edit(item),
                icon: const Icon(Icons.edit),
                label: const Text('Editar reserva'),
              ),
              const SizedBox(height: 12),
              if (item.status == 'PENDIENTE' &&
                  AuthScope.of(context).userRole == 'ADMIN')
                ElevatedButton.icon(
                  onPressed: () {
                    _changeStatus(item, 'CONFIRMADA');
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar reserva'),
                ),
              if (item.status != 'CANCELADA')
                OutlinedButton.icon(
                  onPressed: () {
                    _changeStatus(item, 'CANCELADA');
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar reserva'),
                ),
            ],
          );
        },
      ),
    );
  }

  String _month(int month) {
    return const [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ][month - 1];
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({
    super.key,
    this.initialPeople,
    this.initialDate,
    this.initialTime,
    this.initialTableId,
    this.initialUserId,
  });

  final int? initialPeople;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialTableId;
  final int? initialUserId;

  static int? draftUserId;
  static int? draftTableId;
  static String draftPeople = '';
  static DateTime? draftDate;
  static TimeOfDay? draftTime;

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();

  final peopleController = TextEditingController();

  List<Map<String, dynamic>> tables = const [];

  List<Map<String, dynamic>> users = const [];

  int? selectedUserId;
  int? selectedTableId;

  /// Esta fecha representa Ecuador.
  DateTime? selectedDate;

  TimeOfDay? selectedTime;

  bool saving = false;
  bool loadingTables = true;
  bool loadingUsers = true;

  Map<String, String> serverErrors = {};

  @override
  void initState() {
    super.initState();

    selectedUserId = widget.initialUserId ?? CreateReservationPage.draftUserId;

    selectedTableId =
        widget.initialTableId ?? CreateReservationPage.draftTableId;

    selectedDate = widget.initialDate ?? CreateReservationPage.draftDate;

    selectedTime = widget.initialTime ?? CreateReservationPage.draftTime;

    if (widget.initialPeople != null) {
      peopleController.text = widget.initialPeople.toString();
    } else if (CreateReservationPage.draftPeople.isNotEmpty) {
      peopleController.text = CreateReservationPage.draftPeople;
    }

    _syncDateController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadTables();
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    try {
      final auth = AuthScope.of(context);

      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      if (auth.userRole != 'ADMIN') {
        if (!mounted) return;

        setState(() {
          selectedUserId = auth.userId;
          loadingUsers = false;
        });

        return;
      }

      final result = await ApiService.getUsers(token);

      if (!mounted) return;

      final validUsers = result
          .where((user) => user['id'] is num)
          .map((user) => Map<String, dynamic>.from(user))
          .toList(growable: false);

      setState(() {
        users = validUsers;

        final selectedExists = validUsers.any(
          (user) => (user['id'] as num).toInt() == selectedUserId,
        );

        if (!selectedExists) {
          selectedUserId = null;
        }

        loadingUsers = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        loadingUsers = false;
        serverErrors['usuario'] = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loadingUsers = false;
        serverErrors['usuario'] = 'No fue posible cargar los usuarios.';
      });
    }
  }

  Future<void> _loadTables() async {
    if (!mounted) return;

    setState(() {
      loadingTables = true;
      serverErrors.remove('mesa');
    });

    try {
      final auth = AuthScope.of(context);

      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      DateTime? selectedDateTime;

      if (selectedDate != null) {
        final selectedHour =
            selectedTime ?? const TimeOfDay(hour: 19, minute: 0);

        /// La fecha seleccionada representa Ecuador.
        selectedDateTime = buildEcuadorDateTime(selectedDate!, selectedHour);
      }

      /// Ecuador -> UTC.
      final dateForApi = selectedDateTime == null
          ? null
          : ecuadorToUtc(selectedDateTime);

      debugPrint('========================================');

      debugPrint('MESAS DISPONIBLES');

      debugPrint(
        'ECUADOR - FECHA SELECCIONADA: '
        '$selectedDateTime',
      );

      debugPrint(
        'UTC - FECHA ENVIADA: '
        '${dateForApi?.toIso8601String()}',
      );

      debugPrint('========================================');

      final result = await ApiService.getAvailableTables(
        token,
        date: dateForApi,
      );

      if (!mounted) return;

      final validTables = result
          .where((table) => table['id'] is num && table['numero'] != null)
          .map((table) => Map<String, dynamic>.from(table))
          .toList(growable: false);

      setState(() {
        tables = validTables;

        final selectedExists = validTables.any(
          (table) => (table['id'] as num).toInt() == selectedTableId,
        );

        if (!selectedExists) {
          selectedTableId = null;
        }

        loadingTables = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        tables = [];
        selectedTableId = null;
        loadingTables = false;
        serverErrors['mesa'] = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        tables = [];
        selectedTableId = null;
        loadingTables = false;
        serverErrors['mesa'] =
            'No fue posible consultar las mesas disponibles.\n$error';
      });
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    peopleController.dispose();
    super.dispose();
  }

  /// Actualiza el controlador con la representación UTC.
  ///
  /// Esto evita guardar una fecha local que pueda confundirse
  /// posteriormente con UTC.
  void _syncDateController() {
    if (selectedDate == null) {
      dateController.clear();
      return;
    }

    final time = selectedTime ?? const TimeOfDay(hour: 19, minute: 0);

    final ecuadorDate = buildEcuadorDateTime(selectedDate!, time);

    final utcDate = ecuadorToUtc(ecuadorDate);

    dateController.text = utcDate.toIso8601String();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }

    return null;
  }

  void _saveDraft() {
    CreateReservationPage.draftUserId = selectedUserId;

    CreateReservationPage.draftTableId = selectedTableId;

    CreateReservationPage.draftPeople = peopleController.text;

    /// El draft mantiene la hora seleccionada
    /// como hora de Ecuador.
    CreateReservationPage.draftDate = selectedDate;

    CreateReservationPage.draftTime = selectedTime;
  }

  void _clearDraft() {
    CreateReservationPage.draftUserId = null;

    CreateReservationPage.draftTableId = null;

    CreateReservationPage.draftPeople = '';

    CreateReservationPage.draftDate = null;

    CreateReservationPage.draftTime = null;
  }

  Future<void> _handleReservationNotifications({
    required int reservationId,
    required DateTime ecuadorDateTime,
  }) async {
    if (!mounted) {
      return;
    }

    // ---------------------------------------------------------
    // Explicación antes de solicitar el permiso.
    // ---------------------------------------------------------

    final wantsNotifications = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('Recordatorios')),
            ],
          ),
          content: const Text(
            '¿Deseas recibir una notificación cuando se cree tu reserva '
            'y un recordatorio 30 minutos antes de la hora reservada?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Activar'),
            ),
          ],
        );
      },
    );

    // El usuario decidió no utilizar notificaciones.
    // La reserva ya está creada y continúa funcionando normalmente.
    if (wantsNotifications != true || !mounted) {
      return;
    }

    try {
      final permission = await NotificationService.requestPermission();

      if (!mounted) {
        return;
      }

      switch (permission) {
        case NotificationPermissionResult.granted:
          // ---------------------------------------------------
          // Notificación inmediata.
          // ---------------------------------------------------

          await NotificationService.showReservationCreated(
            reservationId: reservationId,
          );

          // ---------------------------------------------------
          // Recordatorio 30 minutos antes.
          // ---------------------------------------------------

          await NotificationService.scheduleReservationReminder(
            reservationId: reservationId,
            reservationDateTime: ecuadorDateTime,
            minutesBefore: 30,
          );

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notificaciones activadas. Recibirás un recordatorio '
                '30 minutos antes de tu reserva.',
              ),
            ),
          );

          break;

        case NotificationPermissionResult.denied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Las notificaciones fueron rechazadas. '
                'La reserva se creó correctamente.',
              ),
            ),
          );
          break;

        case NotificationPermissionResult.permanentlyDenied:
          await _showNotificationSettingsDialog();
          break;

        case NotificationPermissionResult.restricted:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Las notificaciones están restringidas en este dispositivo. '
                'La reserva se creó correctamente.',
              ),
            ),
          );
          break;

        case NotificationPermissionResult.unavailable:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Las notificaciones no están disponibles. '
                'La reserva se creó correctamente.',
              ),
            ),
          );
          break;
      }
    } catch (error) {
      debugPrint('ERROR NOTIFICACIONES: $error');

      if (!mounted) {
        return;
      }

      // Degradación elegante:
      // una falla en las notificaciones NO afecta la reserva.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La reserva se creó correctamente, '
            'pero no fue posible activar las notificaciones.',
          ),
        ),
      );
    }
  }

  Future<void> _showNotificationSettingsDialog() async {
    if (!mounted) {
      return;
    }

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Notificaciones bloqueadas'),
          content: const Text(
            'El permiso de notificaciones está bloqueado. '
            'Puedes activarlo desde la configuración de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Abrir ajustes'),
            ),
          ],
        );
      },
    );

    if (openSettings == true) {
      await NotificationService.openSettings();
    }
  }

  Future<void> _submit() async {
    if (!mounted) return;

    setState(() {
      serverErrors = {};
    });

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      setState(() {
        serverErrors['fecha'] = 'Seleccione una fecha.';
      });
      return;
    }

    if (selectedTime == null) {
      setState(() {
        serverErrors['fecha'] = 'Seleccione una hora.';
      });
      return;
    }

    // =========================================================
    // ECUADOR -> UTC
    // =========================================================

    final ecuadorDate = buildEcuadorDateTime(selectedDate!, selectedTime!);

    final date = ecuadorToUtc(ecuadorDate);

    final people = int.tryParse(peopleController.text.trim());

    final tableId = selectedTableId;

    if (people == null) {
      setState(() {
        serverErrors['general'] = 'Ingrese un número válido de personas.';
      });
      return;
    }

    if (tableId == null) {
      setState(() {
        serverErrors['mesa'] = 'Seleccione una mesa disponible.';
      });
      return;
    }

    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      setState(() {
        serverErrors['general'] = 'La sesión no está disponible.';
      });
      return;
    }

    if (auth.userRole != 'ADMIN') {
      selectedUserId = auth.userId;
    }

    if (selectedUserId == null) {
      setState(() {
        serverErrors['usuario'] = 'Seleccione un usuario.';
      });
      return;
    }

    // =========================================================
    // DEBUG
    // =========================================================

    debugPrint('========================================');
    debugPrint('CREAR RESERVA');
    debugPrint('RESERVA ECUADOR: $ecuadorDate');
    debugPrint('RESERVA UTC: ${date.toIso8601String()}');
    debugPrint('PERSONAS: $people');
    debugPrint('MESA ID: $tableId');
    debugPrint('USUARIO ID: $selectedUserId');
    debugPrint('========================================');

    setState(() {
      saving = true;
    });

    try {
      // =======================================================
      // CREAR RESERVA EN BACKEND
      // =======================================================

      final reservation = await ApiService.createReservation(
        token: token,
        date: date,
        people: people,
        userId: selectedUserId!,
        tableId: tableId,
      );

      debugPrint('========================================');
      debugPrint('RESERVA CREADA');
      debugPrint('ID: ${reservation.id}');
      debugPrint('ESTADO: ${reservation.status}');
      debugPrint('FECHA BACKEND UTC: ${reservation.date.toIso8601String()}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      // =======================================================
      // GUARDAR Y LIMPIAR BORRADOR
      // =======================================================

      _clearDraft();

      // =======================================================
      // NOTIFICACIONES LOCALES
      // =======================================================
      //
      // IMPORTANTE:
      // ecuadorDate representa la hora que eligió el usuario.
      //
      // Ejemplo:
      // Ecuador: 17/09/2026 20:00
      // UTC:     18/09/2026 01:00
      //
      // Para el recordatorio utilizamos ecuadorDate.
      // NotificationService usa America/Guayaquil.
      // =======================================================

      await _handleReservationNotifications(
        reservationId: reservation.id,
        ecuadorDateTime: ecuadorDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reserva #${reservation.id} creada exitosamente.'),
        ),
      );

      // =======================================================
      // VOLVER A LISTA DE RESERVAS
      // =======================================================

      Navigator.pushReplacementNamed(context, '/app/reservas');
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        setState(() {
          serverErrors['general'] = 'La sesión no pudo ser validada.';
        });
      } else if (error.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso denegado para crear reservas.')),
        );
      } else if (error.statusCode == 422) {
        setState(() {
          serverErrors = error.fieldErrors;
        });

        if (error.fieldErrors.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (!mounted) return;

      debugPrint('ERROR CREANDO RESERVA: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la reserva: $error')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final today = ecuadorToday();

    final currentSelected = selectedDate ?? today;

    final initialDate = currentSelected.isBefore(today)
        ? today
        : currentSelected;

    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: initialDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    final time = selectedTime ?? const TimeOfDay(hour: 19, minute: 0);

    setState(() {
      /// La fecha seleccionada se interpreta
      /// como fecha de Ecuador.
      selectedDate = DateTime(picked.year, picked.month, picked.day);

      selectedTime ??= time;

      final ecuadorDate = buildEcuadorDateTime(selectedDate!, time);

      final utcDate = ecuadorToUtc(ecuadorDate);

      dateController.text = utcDate.toIso8601String();

      selectedTableId = null;

      _saveDraft();
    });

    await _loadTables();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 19, minute: 0),
    );

    if (picked == null || !mounted) {
      return;
    }

    /// Si no existe fecha, usamos HOY DE ECUADOR,
    /// no DateTime.now() del dispositivo.
    final date = selectedDate ?? ecuadorToday();

    setState(() {
      selectedDate = DateTime(date.year, date.month, date.day);

      selectedTime = picked;

      final ecuadorDate = buildEcuadorDateTime(selectedDate!, picked);

      final utcDate = ecuadorToUtc(ecuadorDate);

      dateController.text = utcDate.toIso8601String();

      selectedTableId = null;

      _saveDraft();
    });

    await _loadTables();
  }

  String _dateLabel() {
    if (selectedDate == null) {
      return 'Seleccionar fecha';
    }

    return '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';
  }

  String _timeLabel() {
    if (selectedTime == null) {
      return 'Seleccionar hora';
    }

    return selectedTime!.format(context);
  }

  List<DropdownMenuItem<int>> _userItems() {
    final seen = <int>{};

    return users
        .where((user) {
          final id = (user['id'] as num?)?.toInt();

          return id != null && seen.add(id);
        })
        .map((user) {
          final id = (user['id'] as num).toInt();

          final name =
              '${user['nombre'] ?? ''} '
                      '${user['apellido'] ?? ''}'
                  .trim();

          final email = user['correo']?.toString() ?? '';

          return DropdownMenuItem<int>(
            value: id,
            child: Text(name.isEmpty ? email : name),
          );
        })
        .toList(growable: false);
  }

  List<DropdownMenuItem<int>> _tableItems() {
    final seen = <int>{};

    return tables
        .where((table) {
          final id = (table['id'] as num?)?.toInt();

          return id != null && seen.add(id);
        })
        .map((table) {
          final id = (table['id'] as num).toInt();

          final numero = table['numero']?.toString() ?? id.toString();

          final capacidad = table['capacidad']?.toString();

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              capacidad == null
                  ? 'Mesa $numero'
                  : 'Mesa $numero — $capacidad personas',
            ),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthScope.of(context).userRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Crear nueva reserva',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (isAdmin)
              DropdownButtonFormField<int>(
                key: ValueKey(
                  'user-${users.map((user) => user['id']).join(',')}',
                ),
                initialValue:
                    users.any(
                      (user) => (user['id'] as num?)?.toInt() == selectedUserId,
                    )
                    ? selectedUserId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                hint: Text(
                  loadingUsers ? 'Cargando usuarios...' : 'Seleccionar usuario',
                ),
                items: _userItems(),
                onChanged: loadingUsers
                    ? null
                    : (value) {
                        setState(() {
                          selectedUserId = value;
                          serverErrors.remove('usuario');
                          _saveDraft();
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un usuario.';
                  }

                  return null;
                },
              ),

            if (isAdmin) const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              key: ValueKey(
                'table-${tables.map((table) => table['id']).join(',')}',
              ),
              initialValue:
                  tables.any(
                    (table) =>
                        (table['id'] as num?)?.toInt() == selectedTableId,
                  )
                  ? selectedTableId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Mesa',
                prefixIcon: Icon(Icons.table_restaurant_outlined),
                border: OutlineInputBorder(),
              ),
              hint: Text(
                loadingTables ? 'Cargando mesas...' : 'Seleccionar mesa',
              ),
              items: _tableItems(),
              onChanged: loadingTables
                  ? null
                  : (value) {
                      setState(() {
                        selectedTableId = value;
                        serverErrors.remove('mesa');
                        _saveDraft();
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Seleccione una mesa disponible.';
                }

                return null;
              },
            ),

            if (serverErrors['mesa'] != null &&
                serverErrors['mesa']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  serverErrors['mesa']!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),

            if (!loadingTables && tables.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  selectedDate != null
                      ? 'No hay mesas disponibles para la fecha y hora seleccionadas.'
                      : 'No hay mesas marcadas como disponibles.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            TextFormField(
              controller: peopleController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                _saveDraft();
              },
              decoration: const InputDecoration(
                labelText: 'Número de personas',
                prefixIcon: Icon(Icons.people_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final required = _required(value, 'El número de personas');

                if (required != null) {
                  return required;
                }

                final number = int.tryParse(value!);

                if (number == null || number < 1 || number > 20) {
                  return 'Ingrese entre 1 y 20 personas.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_dateLabel()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(_timeLabel()),
                  ),
                ),
              ],
            ),

            FormField<DateTime>(
              validator: (_) {
                if (selectedDate == null) {
                  return 'Seleccione una fecha.';
                }

                if (selectedTime == null) {
                  return 'Seleccione una hora.';
                }

                return null;
              },
              builder: (field) {
                if (!field.hasError) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),

            if (serverErrors['fecha'] != null &&
                serverErrors['fecha']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  serverErrors['fecha']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            if (serverErrors['usuario'] != null &&
                serverErrors['usuario']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  serverErrors['usuario']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            if (serverErrors['general'] != null &&
                serverErrors['general']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  serverErrors['general']!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: saving ? null : _submit,
                icon: const Icon(Icons.check),
                label: saving
                    ? const Text('Guardando...')
                    : const Text('Crear reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
