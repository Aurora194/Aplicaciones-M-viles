import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'models/reservation.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'auth/auth_scope.dart';

enum ReservationLoadState { loading, empty, error, success }

// ============================================================
// FECHA Y HORA DE ECUADOR
// ============================================================

const Duration _ecuadorUtcOffset = Duration(hours: -5);

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

DateTime ecuadorToday() {
  final now = ecuadorNow();

  return DateTime(now.year, now.month, now.day);
}

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

DateTime buildEcuadorDateTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

// ============================================================
// LISTA DE RESERVAS
// ============================================================

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  ReservationLoadState state = ReservationLoadState.loading;

  List<Reservation> reservations = [];

  String? errorMessage;

  String selectedFilter = 'TODAS';

  // ============================================================
  // PAGINACIÓN
  // ============================================================

  int currentPage = 1;

  final int pageSize = 15;

  bool hasNextPage = false;

  bool changingPage = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = AuthScope.of(context);

      if (!auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

      _load();
    });
  }

  Future<void> _load({int? page}) async {
    if (!mounted) return;

    final requestedPage = page ?? currentPage;

    setState(() {
      state = ReservationLoadState.loading;
      changingPage = true;
      errorMessage = null;
    });

    try {
      final auth = AuthScope.of(context);
      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      final result = await ApiService.getReservations(
        token,
        estado: selectedFilter,
        order: 'asc',
        page: requestedPage,
        limit: pageSize,
      );

      if (!mounted) return;

      final ordered = List<Reservation>.from(result)
        ..sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        currentPage = requestedPage;
        reservations = ordered;

        // Si llegaron 15 registros, puede existir otra página.
        // Si llegaron menos de 15, esta es la última página.
        hasNextPage = ordered.length == pageSize;

        state = ordered.isEmpty
            ? ReservationLoadState.empty
            : ReservationLoadState.success;

        changingPage = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

      setState(() {
        state = ReservationLoadState.error;
        errorMessage = error.message;
        changingPage = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        state = ReservationLoadState.error;
        errorMessage = 'Error al cargar las reservas: $error';
        changingPage = false;
      });
    }
  }

  Future<void> _changeFilter(String value) async {
    if (value == selectedFilter) {
      return;
    }

    setState(() {
      selectedFilter = value;
      currentPage = 1;
      hasNextPage = false;
    });

    await _load(page: 1);
  }

  Future<void> _previousPage() async {
    if (currentPage <= 1 || changingPage) {
      return;
    }

    await _load(page: currentPage - 1);
  }

  Future<void> _nextPage() async {
    if (!hasNextPage || changingPage) {
      return;
    }

    await _load(page: currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthScope.of(context).userRole == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        title: const Text(
          'Reservas',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/app/ai');
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Asistente Leña'),
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
      onRefresh: () => _load(page: currentPage),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Reservas',
                  value: '0',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 70),
          const Icon(
            Icons.event_busy_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              selectedFilter == 'TODAS'
                  ? 'No hay reservas registradas.'
                  : 'No hay reservas con este filtro.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          if (currentPage > 1)
            _PaginationControls(
              currentPage: currentPage,
              hasNextPage: false,
              changingPage: changingPage,
              onPrevious: _previousPage,
              onNext: _nextPage,
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isAdmin) {
    final confirmedCount = reservations
        .where((item) => item.status.toUpperCase() == 'CONFIRMADA')
        .length;

    return RefreshIndicator(
      onRefresh: () => _load(page: currentPage),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 20),
          _ReservationFilter(value: selectedFilter, onChanged: _changeFilter),
          const SizedBox(height: 18),
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
                  await _load(page: currentPage);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          _PaginationControls(
            currentPage: currentPage,
            hasNextPage: hasNextPage,
            changingPage: changingPage,
            onPrevious: _previousPage,
            onNext: _nextPage,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGINACIÓN
// ============================================================

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.hasNextPage,
    required this.changingPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final bool hasNextPage;
  final bool changingPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E1DF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: currentPage > 1 && !changingPage ? onPrevious : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 12),
          Text(
            'Página $currentPage',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: hasNextPage && !changingPage ? onNext : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESUMEN
// ============================================================

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E1DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTONES PRINCIPALES
// ============================================================

class _NewReservationButton extends StatelessWidget {
  const _NewReservationButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
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
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/app/mesas');
        },
        icon: const Icon(Icons.table_restaurant_outlined),
        label: const Text('Gestionar mesas'),
      ),
    );
  }
}

// ============================================================
// FILTRO
// ============================================================

class _ReservationFilter extends StatelessWidget {
  const _ReservationFilter({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const options = ['TODAS', 'PENDIENTE', 'CONFIRMADA', 'CANCELADA'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final selected = value == option;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                option == 'TODAS'
                    ? 'Todas'
                    : option[0] + option.substring(1).toLowerCase(),
              ),
              selected: selected,
              onSelected: (_) {
                onChanged(option);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// TARJETA DE RESERVA
// ============================================================

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.item, required this.onTap});

  final Reservation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
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
                      borderRadius: BorderRadius.circular(7),
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
              const SizedBox(height: 6),
              Text(
                AuthScope.of(context).userRole == 'ADMIN'
                    ? item.clientName ?? 'Reserva de mesa'
                    : 'Mi reserva',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 12,
                runSpacing: 7,
                children: [
                  _ReservationMeta(
                    icon: Icons.calendar_today_outlined,
                    text:
                        '${item.date.day} ${_month(item.date.month)} ${item.date.year}',
                  ),
                  _ReservationMeta(
                    icon: Icons.access_time_outlined,
                    text:
                        '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
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

// ============================================================
// DETALLE DE RESERVA
// ============================================================

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

    if (confirmed != true || !mounted) {
      return;
    }

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

      // ========================================================
      // NOTIFICACIONES
      // ========================================================

      if (status == 'CONFIRMADA') {
        await NotificationService.requestPermission();

        await NotificationService.showReservationConfirmed(
          reservationId: item.id,
        );
      } else if (status == 'CANCELADA') {
        await NotificationService.cancelReservationReminder(item.id);

        await NotificationService.requestPermission();

        await NotificationService.showReservationCancelled(
          reservationId: item.id,
        );
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

      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

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

    DateTime editDate = utcToEcuador(item.date);

    TimeOfDay editTime = TimeOfDay.fromDateTime(editDate);

    bool savingEdit = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                    const SizedBox(height: 14),
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
                                firstDate: ecuadorToday(),
                                lastDate: ecuadorToday().add(
                                  const Duration(days: 365),
                                ),
                                initialDate: editDate,
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
                            label: Text(_formatTime(editTime)),
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
                            final auth = AuthScope.of(context);

                            final token = auth.accessToken;

                            if (token == null || token.isEmpty) {
                              throw const ApiException(
                                401,
                                'Sesión no disponible.',
                              );
                            }

                            await ApiService.updateReservation(
                              token: token,
                              id: item.id,
                              date: ecuadorToUtc(editDate),
                              people: int.parse(peopleController.text),
                              userId: auth.userId ?? 0,
                              tableId: item.tableId,
                            );

                            // Cancelar recordatorio anterior.
                            await NotificationService.cancelReservationReminder(
                              item.id,
                            );

                            // Programar nuevo recordatorio.
                            await NotificationService.requestPermission();

                            await NotificationService.scheduleReservationReminder(
                              reservationId: item.id,
                              reservationDateTime: editDate,
                              minutesBefore: 30,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext, true);
                          } on ApiException catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                savingEdit = false;
                              });
                            }

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                  child: savingEdit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
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

  Future<void> _delete(Reservation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar reserva'),
          content: Text('¿Desea eliminar la reserva #${item.id}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final token = AuthScope.of(context).accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'Sesión no disponible.');
      }

      await ApiService.deleteReservation(token: token, id: item.id);

      // Cancelar todas las notificaciones asociadas.
      await NotificationService.cancelReservationNotification(item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reserva eliminada.')));

      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthScope.of(context).userRole == 'ADMIN';

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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Detalle de reserva #${item.id}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E1DF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la reserva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                            '${utcToEcuador(item.date).day} ${_month(utcToEcuador(item.date).month)} ${utcToEcuador(item.date).year}',
                      ),
                      _DetailRow(
                        icon: Icons.access_time_outlined,
                        label: 'Hora',
                        value:
                            '${utcToEcuador(item.date).hour.toString().padLeft(2, '0')}:${utcToEcuador(item.date).minute.toString().padLeft(2, '0')}',
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
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _edit(item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar reserva'),
              ),
              const SizedBox(height: 10),
              if (isAdmin && item.status == 'PENDIENTE')
                ElevatedButton.icon(
                  onPressed: () => _changeStatus(item, 'CONFIRMADA'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar reserva'),
                ),
              if (item.status != 'CANCELADA')
                OutlinedButton.icon(
                  onPressed: () => _changeStatus(item, 'CANCELADA'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar reserva'),
                ),
              if (isAdmin) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar reserva'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ],
          );
        },
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NUEVA RESERVA
// ============================================================

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({super.key});

  static String? draftPeople;
  static DateTime? draftDate;
  static TimeOfDay? draftTime;

  static int? draftTableId;

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final _formKey = GlobalKey<FormState>();

  final _peopleController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<Map<String, dynamic>> tables = [];

  int? selectedTableId;

  bool loadingTables = false;
  bool saving = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _applyDraft();
  }

  void _applyDraft() {
    final draftPeople = CreateReservationPage.draftPeople;

    final draftDate = CreateReservationPage.draftDate;

    final draftTime = CreateReservationPage.draftTime;

    _peopleController.text = draftPeople ?? '';

    selectedDate = draftDate;
    selectedTime = draftTime;

    selectedTableId = null;

    CreateReservationPage.draftPeople = null;
    CreateReservationPage.draftDate = null;
    CreateReservationPage.draftTime = null;
    CreateReservationPage.draftTableId = null;

    if (selectedDate != null && selectedTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _loadTables();
      });
    }
  }

  Future<void> _loadTables() async {
    if (!mounted) return;

    if (selectedDate == null || selectedTime == null) {
      setState(() {
        tables = [];
        selectedTableId = null;
        loadingTables = false;
      });

      return;
    }

    setState(() {
      loadingTables = true;
      errorMessage = null;
      selectedTableId = null;
    });

    try {
      final auth = AuthScope.of(context);
      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      final ecuadorDateTime = buildEcuadorDateTime(
        selectedDate!,
        selectedTime!,
      );

      final utcDateTime = ecuadorToUtc(ecuadorDateTime);

      debugPrint('CONSULTANDO MESAS DISPONIBLES:');

      debugPrint(utcDateTime.toIso8601String());

      final result = await ApiService.getAvailableTables(
        token,
        date: utcDateTime,
      );

      debugPrint('RESPUESTA MESAS DISPONIBLES: $result');

      if (!mounted) return;

      final validTables = result
          .where((item) => item['id'] is num && item['numero'] != null)
          .map(
            (item) => <String, dynamic>{
              'id': (item['id'] as num).toInt(),
              'numero': item['numero'].toString(),
              'capacidad': item['capacidad'] is num
                  ? (item['capacidad'] as num).toInt()
                  : 0,
              'disponible': item['disponible'] == true,
            },
          )
          .toList();

      setState(() {
        tables = validTables;
        selectedTableId = null;
        loadingTables = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: '/app/reservas/nueva',
        );

        return;
      }

      setState(() {
        tables = [];
        selectedTableId = null;
        loadingTables = false;
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        tables = [];
        selectedTableId = null;
        loadingTables = false;
        errorMessage = 'No fue posible consultar las mesas disponibles.';
      });

      debugPrint('ERROR MESAS: $error');
    }
  }

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ecuadorToday();

    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: selectedDate != null && !selectedDate!.isBefore(today)
          ? selectedDate!
          : today,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);

      selectedTableId = null;
      errorMessage = null;
    });

    if (selectedTime != null) {
      await _loadTables();
    }
  }

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
      selectedTableId = null;
      errorMessage = null;
    });

    if (selectedDate != null) {
      await _loadTables();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateDisplay(DateTime date) {
    final today = ecuadorToday();
    final tomorrow = today.add(const Duration(days: 1));

    if (_sameDate(date, today)) {
      return 'Hoy · ${_formatDate(date)}';
    }

    if (_sameDate(date, tomorrow)) {
      return 'Mañana · ${_formatDate(date)}';
    }

    return _formatDate(date);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  int? _peopleCount() {
    return int.tryParse(_peopleController.text.trim());
  }

  Map<String, dynamic>? _selectedTable() {
    if (selectedTableId == null) {
      return null;
    }

    for (final table in tables) {
      final id = (table['id'] as num?)?.toInt();

      if (id == selectedTableId) {
        return table;
      }
    }

    return null;
  }

  bool _tableCanFit(Map<String, dynamic> table) {
    final people = _peopleCount();

    if (people == null) {
      return true;
    }

    final capacity = (table['capacidad'] as num?)?.toInt() ?? 0;

    return capacity >= people;
  }

  void _selectTable(Map<String, dynamic> table) {
    final id = (table['id'] as num?)?.toInt();

    if (id == null) return;

    if (!_tableCanFit(table)) {
      final people = _peopleCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            people == null
                ? 'Esta mesa no está disponible para la reserva.'
                : 'Esta mesa tiene capacidad para ${table['capacidad']} personas.',
          ),
        ),
      );

      return;
    }

    setState(() {
      selectedTableId = id;
      errorMessage = null;
    });
  }

  Future<void> _showReservationSummary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorMessage = 'Seleccione fecha y hora.';
      });

      return;
    }

    final table = _selectedTable();

    if (table == null) {
      setState(() {
        errorMessage = 'Seleccione una mesa disponible.';
      });

      return;
    }

    final people = _peopleCount() ?? 0;

    final capacity = (table['capacidad'] as num?)?.toInt() ?? 0;

    if (people > capacity) {
      setState(() {
        errorMessage = 'La mesa seleccionada no tiene capacidad suficiente.';
      });

      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resumen de reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryLine(
                icon: Icons.people_alt_outlined,
                label: '$people personas',
              ),
              const SizedBox(height: 10),
              _SummaryLine(
                icon: Icons.calendar_today_outlined,
                label: _formatDateDisplay(selectedDate!),
              ),
              const SizedBox(height: 10),
              _SummaryLine(
                icon: Icons.access_time_outlined,
                label: _formatTime(selectedTime!),
              ),
              const SizedBox(height: 10),
              _SummaryLine(
                icon: Icons.table_restaurant_outlined,
                label: 'Mesa ${table['numero']}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CREAR RESERVA + NOTIFICACIONES
  // ============================================================

  Future<void> _submit() async {
    if (!mounted) return;

    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      setState(() {
        errorMessage = 'Seleccione una fecha.';
      });

      return;
    }

    if (selectedTime == null) {
      setState(() {
        errorMessage = 'Seleccione una hora.';
      });

      return;
    }

    final people = _peopleCount();

    if (people == null || people < 1 || people > 20) {
      setState(() {
        errorMessage = 'Ingrese entre 1 y 20 personas.';
      });

      return;
    }

    final table = _selectedTable();

    if (table == null || selectedTableId == null) {
      setState(() {
        errorMessage = 'Seleccione una mesa disponible.';
      });

      return;
    }

    final capacity = (table['capacidad'] as num?)?.toInt() ?? 0;

    if (people > capacity) {
      setState(() {
        errorMessage =
            'La mesa seleccionada tiene capacidad para $capacity personas.';
      });

      return;
    }

    final auth = AuthScope.of(context);
    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      setState(() {
        errorMessage = 'La sesión no está disponible.';
      });

      return;
    }

    final userId = auth.userId;

    if (userId == null) {
      setState(() {
        errorMessage = 'No se pudo identificar al usuario.';
      });

      return;
    }

    final ecuadorDateTime = buildEcuadorDateTime(selectedDate!, selectedTime!);

    final utcDateTime = ecuadorToUtc(ecuadorDateTime);

    setState(() {
      saving = true;
    });

    try {
      // --------------------------------------------------------
      // 1. Pedir permiso correctamente.
      // --------------------------------------------------------

      final permission = await NotificationService.requestPermission();

      debugPrint('PERMISO NOTIFICACIONES: $permission');

      // --------------------------------------------------------
      // 2. Crear reserva.
      // --------------------------------------------------------

      final reservation = await ApiService.createReservation(
        token: token,
        date: utcDateTime,
        people: people,
        userId: userId,
        tableId: selectedTableId!,
      );

      // --------------------------------------------------------
      // 3. Mostrar inmediatamente "Reserva creada".
      //
      // Se utiliza el ID REAL devuelto por el backend.
      // --------------------------------------------------------

      await NotificationService.showReservationCreated(
        reservationId: reservation.id,
      );

      // --------------------------------------------------------
      // 4. Programar recordatorio 30 minutos antes.
      //
      // La fecha se envía como hora local de Ecuador.
      // --------------------------------------------------------

      await NotificationService.scheduleReservationReminder(
        reservationId: reservation.id,
        reservationDateTime: ecuadorDateTime,
        minutesBefore: 30,
      );

      if (!mounted) return;

      CreateReservationPage.draftPeople = null;
      CreateReservationPage.draftDate = null;
      CreateReservationPage.draftTime = null;
      CreateReservationPage.draftTableId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada exitosamente.')),
      );

      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: '/app/reservas/nueva',
        );

        return;
      }

      if (error.statusCode == 403) {
        setState(() {
          errorMessage = 'No tiene permisos para crear esta reserva.';
        });

        return;
      }

      if (error.statusCode == 422) {
        setState(() {
          errorMessage = error.message;
        });

        return;
      }

      setState(() {
        errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error al crear la reserva.';
      });

      debugPrint('ERROR CREANDO RESERVA: $error');
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Widget _buildReservationContext() {
    if (selectedDate == null || selectedTime == null) {
      return const SizedBox.shrink();
    }

    final people = _peopleCount();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E1DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 20,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateDisplay(selectedDate!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hora ${_formatTime(selectedTime!)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (people != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2F0),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 15,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$people',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTablesSection() {
    if (selectedDate == null || selectedTime == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E1DF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_note_outlined, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seleccione fecha y hora para consultar las mesas disponibles.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (loadingTables) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E1DF)),
        ),
        child: const Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 10),
            Text(
              'Consultando mesas disponibles...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: .25)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadTables,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E1DF)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 9),
            Text(
              'No hay mesas disponibles',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'No encontramos mesas libres para la fecha y hora seleccionadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final people = _peopleCount();

    final suitableCount = tables.where(_tableCanFit).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReservationContext(),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_restaurant_outlined,
                size: 19,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesas disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Toque una mesa para seleccionarla',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEEC),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$suitableCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (people != null && suitableCount == 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hay mesas disponibles, pero ninguna tiene capacidad para $people personas.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...tables.map(
          (table) => _TableSelectionCard(
            table: table,
            selected: (table['id'] as num?)?.toInt() == selectedTableId,
            canFit: _tableCanFit(table),
            onTap: () {
              _selectTable(table);
            },
          ),
        ),
        if (selectedTableId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 17,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Mesa ${_selectedTable()?['numero'] ?? ''} seleccionada',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            const Text(
              'Crear nueva reserva',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Complete los datos y seleccione directamente una mesa disponible.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 22),

            // PERSONAS
            TextFormField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (selectedTableId != null) {
                  final table = _selectedTable();

                  if (table != null && !_tableCanFit(table)) {
                    setState(() {
                      selectedTableId = null;
                    });
                  } else {
                    setState(() {});
                  }
                } else {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                labelText: 'Número de personas',
                hintText: 'Ejemplo: 4',
                prefixIcon: const Icon(Icons.people_alt_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
                ),
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');

                if (number == null || number < 1 || number > 20) {
                  return 'Ingrese entre 1 y 20 personas.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // FECHA Y HORA
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today_outlined,
                    label: selectedDate == null
                        ? 'Seleccionar fecha'
                        : _formatDateDisplay(selectedDate!),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.access_time_outlined,
                    label: selectedTime == null
                        ? 'Seleccionar hora'
                        : _formatTime(selectedTime!),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            _buildTablesSection(),

            if (errorMessage != null && tables.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 20),

            // RESUMEN
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: saving ? null : _showReservationSummary,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver resumen'),
              ),
            ),

            const SizedBox(height: 10),

            // CREAR
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: saving ? null : _submit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(saving ? 'Creando reserva...' : 'Crear reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TARJETA DE MESA
// ============================================================

class _TableSelectionCard extends StatelessWidget {
  const _TableSelectionCard({
    required this.table,
    required this.selected,
    required this.canFit,
    required this.onTap,
  });

  final Map<String, dynamic> table;
  final bool selected;
  final bool canFit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = table['numero']?.toString() ?? 'Mesa';

    final capacity = (table['capacidad'] as num?)?.toInt() ?? 0;

    final enabled = canFit || _peopleValueMissing();

    final primary = AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? onTap
              : () {
                  onTap();
                },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: .09)
                  : enabled
                  ? Colors.white
                  : const Color(0xFFF2F0EF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? primary : const Color(0xFFE4E1DF),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: .14)
                        : const Color(0xFFF4F1EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.table_restaurant_outlined,
                    size: 22,
                    color: selected ? primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa $number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hasta $capacity personas',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!canFit && !_peopleValueMissing())
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Capacidad insuficiente',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selected
                          ? null
                          : Border.all(color: const Color(0xFFD8D3D0)),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 17, color: Colors.white)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _peopleValueMissing() {
    return false;
  }
}

// ============================================================
// BOTÓN FECHA / HORA
// ============================================================

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

// ============================================================
// LÍNEA DE RESUMEN
// ============================================================

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primaryLight),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

// ============================================================
// ERROR
// ============================================================

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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// UTILIDADES
// ============================================================

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

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
