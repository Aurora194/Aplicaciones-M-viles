import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'models/reservation.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'auth/auth_scope.dart';

enum ReservationLoadState { loading, empty, error, success }

const Duration _ecuadorUtcOffset = Duration(hours: -5);

/* ============================================================
   FECHA Y HORA ECUADOR
   ============================================================ */

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

/* ============================================================
   LISTA DE RESERVAS
   ============================================================ */

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  ReservationLoadState state = ReservationLoadState.loading;

  List<Reservation> reservations = const [];

  String? errorMessage;

  String selectedStatus = 'TODAS';

  /* ==========================================================
     PAGINACIÓN
     ========================================================== */

  static const int pageSize = 15;

  int currentPage = 1;

  bool hasNextPage = false;

  bool hasPreviousPage = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = AuthScope.of(context);

      if (auth.accessToken == null || auth.accessToken!.isEmpty) {
        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

      _load();
    });
  }

  /* ==========================================================
     CARGAR RESERVAS
     ========================================================== */

  Future<void> _load({int? page}) async {
    if (!mounted) return;

    final requestedPage = page ?? currentPage;

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

      /*
       * Si hay filtro, lo mandamos al backend.
       */
      final String? estado = selectedStatus == 'TODAS' ? null : selectedStatus;

      final result = await ApiService.getReservations(
        token,
        page: requestedPage,
        limit: pageSize,
        order: 'asc',
        estado: estado,
      );

      if (!mounted) return;

      /*
       * Como getReservations devuelve
       * solamente la lista, determinamos
       * si existe una página siguiente
       * cuando recibimos exactamente 15.
       */
      final next = result.length == pageSize;

      /*
       * Si la página solicitada quedó
       * vacía y no estamos en la primera,
       * regresamos automáticamente a la
       * página anterior.
       */
      if (result.isEmpty && requestedPage > 1) {
        await _load(page: requestedPage - 1);

        return;
      }

      setState(() {
        reservations = result;

        currentPage = requestedPage;

        hasNextPage = next;

        hasPreviousPage = requestedPage > 1;

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

  /* ==========================================================
     PÁGINA ANTERIOR
     ========================================================== */

  Future<void> _previousPage() async {
    if (!hasPreviousPage) {
      return;
    }

    await _load(page: currentPage - 1);
  }

  /* ==========================================================
     PÁGINA SIGUIENTE
     ========================================================== */

  Future<void> _nextPage() async {
    if (!hasNextPage) {
      return;
    }

    await _load(page: currentPage + 1);
  }

  /* ==========================================================
     FILTRO
     ========================================================== */

  Future<void> _showFilterDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filtrar reservas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterOption(
                title: 'Todas',
                value: 'TODAS',
                selected: selectedStatus == 'TODAS',
                onTap: () {
                  Navigator.pop(dialogContext, 'TODAS');
                },
              ),
              _FilterOption(
                title: 'Pendientes',
                value: 'PENDIENTE',
                selected: selectedStatus == 'PENDIENTE',
                onTap: () {
                  Navigator.pop(dialogContext, 'PENDIENTE');
                },
              ),
              _FilterOption(
                title: 'Confirmadas',
                value: 'CONFIRMADA',
                selected: selectedStatus == 'CONFIRMADA',
                onTap: () {
                  Navigator.pop(dialogContext, 'CONFIRMADA');
                },
              ),
              _FilterOption(
                title: 'Canceladas',
                value: 'CANCELADA',
                selected: selectedStatus == 'CANCELADA',
                onTap: () {
                  Navigator.pop(dialogContext, 'CANCELADA');
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      selectedStatus = selected;

      currentPage = 1;
    });

    await _load(page: 1);
  }

  /* ==========================================================
     NUEVA RESERVA
     ========================================================== */

  Future<void> _newReservation() async {
    final result = await Navigator.pushNamed(context, '/app/reservas/nueva');

    if (!mounted) return;

    if (result == true) {
      await _load(page: currentPage);
    }
  }

  /* ==========================================================
     GESTIONAR MESAS
     ========================================================== */

  Future<void> _manageTables() async {
    await Navigator.pushNamed(context, '/app/mesas');

    if (!mounted) return;

    await _load(page: currentPage);
  }

  /* ==========================================================
     ASISTENTE
     ========================================================== */

  Future<void> _openAssistant() async {
    await Navigator.pushNamed(context, '/app/ai');

    if (!mounted) return;

    await _load(page: currentPage);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    final admin = auth.userRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(admin ? 'Gestionar reservas' : 'Mis reservas'),
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Filtrar reservas',
              onPressed: _showFilterDialog,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list_outlined),
                  if (selectedStatus != 'TODAS')
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _load(page: currentPage),
        child: _buildBody(admin),
      ),

      /* ========================================================
         ASISTENTE LEÑA
         ======================================================== */
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssistant,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Asistente Leña'),
      ),
    );
  }

  /* ==========================================================
     CUERPO
     ========================================================== */

  Widget _buildBody(bool admin) {
    if (state == ReservationLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == ReservationLoadState.error) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),

          const Icon(Icons.error_outline, size: 64, color: Colors.red),

          const SizedBox(height: 16),

          const Text(
            'No fue posible cargar las reservas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () => _load(page: currentPage),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (state == ReservationLoadState.empty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),

          Icon(
            Icons.event_busy_outlined,
            size: 72,
            color: AppColors.primaryLight,
          ),

          const SizedBox(height: 20),

          Text(
            admin ? 'No existen reservas registradas' : 'No tienes reservas',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            admin
                ? 'Las reservas de los clientes aparecerán aquí.'
                : 'Puedes crear una nueva reserva desde la aplicación.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          if (admin)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _newReservation,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva reserva'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _manageTables,
                    icon: const Icon(Icons.table_restaurant_outlined),
                    label: const Text('Gestionar mesas'),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _newReservation,
              icon: const Icon(Icons.add),
              label: const Text('Nueva reserva'),
            ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),

      children: [
        /* ======================================================
           RESUMEN
           ====================================================== */
        _SummaryCard(
          visible: reservations.length,
          filter: selectedStatus,
          isAdmin: admin,
          page: currentPage,
          pageSize: pageSize,
        ),

        const SizedBox(height: 14),

        /* ======================================================
           BOTONES
           ====================================================== */
        if (admin)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _newReservation,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva reserva'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _manageTables,
                  icon: const Icon(Icons.table_restaurant_outlined),
                  label: const Text('Gestionar mesas'),
                ),
              ),
            ],
          ),

        if (admin) const SizedBox(height: 18),

        /* ======================================================
           RESERVAS
           ====================================================== */
        ...reservations.map((reservation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),

            child: ReservationCard(
              reservation: reservation,
              isAdmin: admin,
              onChanged: () => _load(page: currentPage),
            ),
          );
        }),

        const SizedBox(height: 8),

        /* ======================================================
           PAGINACIÓN
           ====================================================== */
        _PaginationControls(
          currentPage: currentPage,
          hasPrevious: hasPreviousPage,
          hasNext: hasNextPage,
          onPrevious: _previousPage,
          onNext: _nextPage,
        ),
      ],
    );
  }
}

/* ============================================================
   FILTRO
   ============================================================ */

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Radio<bool>(
        value: true,
        groupValue: selected ? true : null,
        onChanged: (_) => onTap(),
      ),

      title: Text(title),

      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryLight)
          : null,

      onTap: onTap,
    );
  }
}

/* ============================================================
   RESUMEN
   ============================================================ */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.visible,
    required this.filter,
    required this.isAdmin,
    required this.page,
    required this.pageSize,
  });

  final int visible;
  final String filter;
  final bool isAdmin;
  final int page;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    final filterText = switch (filter) {
      'PENDIENTE' => 'Pendientes',

      'CONFIRMADA' => 'Confirmadas',

      'CANCELADA' => 'Canceladas',

      _ => 'Todas',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),

              child: Icon(
                Icons.event_note_outlined,
                color: AppColors.primaryLight,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    isAdmin ? 'Reservas de clientes' : 'Mis reservas',

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    filter == 'TODAS'
                        ? '$visible reservas en esta página'
                        : '$visible reservas · $filterText',
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Página $page · $pageSize por página',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

/* ============================================================
   PAGINACIÓN
   ============================================================ */

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

        child: Row(
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: hasPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
            ),

            Expanded(
              child: Text(
                'Página $currentPage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            IconButton(
              tooltip: 'Página siguiente',
              onPressed: hasNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   TARJETA DE RESERVA
   ============================================================ */

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.isAdmin,
    this.onChanged,
  });

  final Reservation reservation;
  final bool isAdmin;

  final Future<void> Function()? onChanged;

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMADA':
        return 'Confirmada';

      case 'CANCELADA':
        return 'Cancelada';

      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMADA':
        return Colors.green;

      case 'CANCELADA':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Future<void> _openDetail(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      '/app/reservas/${reservation.id}',
    );

    if (result == true) {
      await onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecuadorDate = utcToEcuador(reservation.date);

    final dateText =
        '${ecuadorDate.day.toString().padLeft(2, '0')}/'
        '${ecuadorDate.month.toString().padLeft(2, '0')}/'
        '${ecuadorDate.year}';

    final timeText =
        '${ecuadorDate.hour.toString().padLeft(2, '0')}:'
        '${ecuadorDate.minute.toString().padLeft(2, '0')}';

    final statusColor = _statusColor(reservation.status);

    final clientName = reservation.clientName ?? 'Cliente';

    final tableText = reservation.tableNumber?.trim().isNotEmpty == true
        ? reservation.tableNumber!
        : 'No asignada';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () => _openDetail(context),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reserva #${reservation.id}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      _statusLabel(reservation.status),

                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _CardInfoRow(
                icon: Icons.table_restaurant_outlined,
                text: 'Mesa: $tableText',
              ),

              if (isAdmin)
                _CardInfoRow(icon: Icons.person_outline, text: clientName),

              _CardInfoRow(icon: Icons.calendar_today_outlined, text: dateText),

              _CardInfoRow(icon: Icons.access_time_outlined, text: timeText),

              _CardInfoRow(
                icon: Icons.people_outline,
                text: '${reservation.people} persona(s)',
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,

                child: TextButton.icon(
                  onPressed: () => _openDetail(context),

                  icon: const Icon(Icons.arrow_forward),

                  label: const Text('Ver detalle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   FILA DE INFORMACIÓN
   ============================================================ */

class _CardInfoRow extends StatelessWidget {
  const _CardInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primaryLight),

          const SizedBox(width: 10),

          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/* ============================================================
   DETALLE DE RESERVA
   ============================================================ */

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

    if (initialized) {
      return;
    }

    initialized = true;

    request = _loadReservation();
  }

  Future<Reservation> _loadReservation() async {
    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'La sesión no está disponible.');
    }

    return ApiService.getReservation(token, widget.id);
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {
      request = _loadReservation();
    });
  }

  /* ==========================================================
     CAMBIAR ESTADO
     ========================================================== */

  Future<void> _changeStatus(Reservation item, String status) async {
    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      _showMessage('La sesión no está disponible.', isError: true);

      return;
    }

    final isConfirm = status == 'CONFIRMADA';

    final isCancel = status == 'CANCELADA';

    final actionText = isConfirm ? 'confirmar' : 'cancelar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isConfirm ? 'Confirmar reserva' : 'Cancelar reserva'),

          content: Text('¿Deseas $actionText la reserva #${item.id}?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: Text(isConfirm ? 'Confirmar' : 'Cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ApiService.updateReservationStatus(
        token: token,
        id: item.id,
        status: status,
      );

      if (isCancel) {
        await NotificationService.cancelReservationNotification(item.id);
      }

      if (!mounted) return;

      _showMessage(
        isConfirm
            ? 'Reserva confirmada correctamente.'
            : 'Reserva cancelada correctamente.',
      );

      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'No fue posible actualizar la reserva: $error',
        isError: true,
      );
    }
  }

  /* ==========================================================
     ELIMINAR
     ========================================================== */

  Future<void> _deleteReservation(Reservation item) async {
    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      _showMessage('La sesión no está disponible.', isError: true);

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar reserva'),

          content: Text(
            '¿Deseas eliminar la reserva #${item.id}?\n\n'
            'La reserva dejará de aparecer en el listado.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

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
      /*
       * El backend ahora coloca
       * deletedAt.
       */
      await ApiService.deleteReservation(token: token, id: item.id);

      if (!mounted) return;

      /*
       * true hace que la página
       * anterior vuelva a consultar
       * el backend.
       */
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;

      _showMessage('No fue posible eliminar la reserva: $error', isError: true);
    }
  }

  /* ==========================================================
     EDITAR
     ========================================================== */

  Future<void> _edit(Reservation item) async {
    final result = await Navigator.pushNamed(
      context,
      '/app/reservas/editar/${item.id}',
    );

    if (!mounted) return;

    if (result == true) {
      _refresh();
    }
  }

  /* ==========================================================
     MENSAJE
     ========================================================== */

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMADA':
        return 'Confirmada';

      case 'CANCELADA':
        return 'Cancelada';

      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMADA':
        return Colors.green;

      case 'CANCELADA':
        return Colors.red;

      default:
        return Colors.orange;
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

          if (snapshot.hasError) {
            final error = snapshot.error;

            final message = error is ApiException
                ? error.message
                : 'No fue posible cargar la reserva.\n$error';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    Text(message, textAlign: TextAlign.center),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = snapshot.data;

          if (item == null) {
            return const Center(child: Text('Reserva no encontrada.'));
          }

          return _buildDetail(item);
        },
      ),
    );
  }

  /* ==========================================================
     DETALLE
     ========================================================== */

  Widget _buildDetail(Reservation item) {
    final ecuadorDate = utcToEcuador(item.date);

    final dateText =
        '${ecuadorDate.day.toString().padLeft(2, '0')}/'
        '${ecuadorDate.month.toString().padLeft(2, '0')}/'
        '${ecuadorDate.year}';

    final timeText =
        '${ecuadorDate.hour.toString().padLeft(2, '0')}:'
        '${ecuadorDate.minute.toString().padLeft(2, '0')}';

    final statusColor = _statusColor(item.status);

    final statusLabel = _statusLabel(item.status);

    final admin = AuthScope.of(context).userRole == 'ADMIN';

    final canConfirm = admin && item.status.toUpperCase() == 'PENDIENTE';

    final canCancel = item.status.toUpperCase() != 'CANCELADA';

    final canDelete = admin;

    final tableText = item.tableNumber?.trim().isNotEmpty == true
        ? item.tableNumber!
        : 'No asignada';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,

                  backgroundColor: statusColor.withValues(alpha: 0.12),

                  child: Icon(Icons.event_note, size: 34, color: statusColor),
                ),

                const SizedBox(height: 14),

                Text(
                  'Reserva #${item.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Información de la reserva',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                _DetailRow(
                  icon: Icons.table_restaurant_outlined,
                  label: 'Mesa',
                  value: tableText,
                ),

                if (admin)
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Cliente',
                    value: item.clientName ?? 'Cliente',
                  ),

                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: dateText,
                ),

                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Hora',
                  value: timeText,
                ),

                _DetailRow(
                  icon: Icons.people_outline,
                  label: 'Personas',
                  value: '${item.people}',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Acciones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        /* EDITAR */
        ElevatedButton.icon(
          onPressed: item.status.toUpperCase() == 'CANCELADA'
              ? null
              : () => _edit(item),

          icon: const Icon(Icons.edit),

          label: const Text('Editar reserva'),
        ),

        const SizedBox(height: 10),

        /* CONFIRMAR */
        if (canConfirm)
          ElevatedButton.icon(
            onPressed: () => _changeStatus(item, 'CONFIRMADA'),

            icon: const Icon(Icons.check_circle_outline),

            label: const Text('Confirmar reserva'),
          ),

        if (canConfirm) const SizedBox(height: 10),

        /* CANCELAR */
        if (canCancel)
          OutlinedButton.icon(
            onPressed: () => _changeStatus(item, 'CANCELADA'),

            icon: const Icon(Icons.cancel_outlined),

            label: const Text('Cancelar reserva'),
          ),

        if (canCancel && canDelete) const SizedBox(height: 10),

        /* ELIMINAR */
        if (canDelete)
          OutlinedButton.icon(
            onPressed: () => _deleteReservation(item),

            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,

              side: const BorderSide(color: Colors.red),
            ),

            icon: const Icon(Icons.delete_outline),

            label: const Text('Eliminar reserva'),
          ),

        if (!admin)
          Padding(
            padding: const EdgeInsets.only(top: 16),

            child: Text(
              item.status.toUpperCase() == 'CANCELADA'
                  ? 'Esta reserva ya está cancelada.'
                  : 'Como cliente, solo puedes cancelar tu propia reserva.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

/* ============================================================
   FILA DEL DETALLE
   ============================================================ */

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
        crossAxisAlignment: CrossAxisAlignment.start,

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

/* ============================================================
   CREAR RESERVA
   ============================================================ */

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({super.key});

  /*
   * El asistente solamente
   * entrega datos de fecha,
   * hora y personas.
   *
   * La mesa NO se selecciona
   * automáticamente.
   */
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

  DateTime selectedDate = ecuadorToday();

  TimeOfDay selectedTime = TimeOfDay.fromDateTime(ecuadorNow());

  List<Map<String, dynamic>> tables = [];

  /*
   * IMPORTANTE:
   *
   * Siempre inicia null.
   * No hay mesa seleccionada.
   */
  int? selectedTableId;

  bool loadingTables = true;

  bool saving = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _applyDraft();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadTables();
    });
  }

  /* ==========================================================
     BORRADOR DEL ASISTENTE
     ========================================================== */

  void _applyDraft() {
    final draftPeople = CreateReservationPage.draftPeople;

    final draftDate = CreateReservationPage.draftDate;

    final draftTime = CreateReservationPage.draftTime;

    /*
     * NO usamos draftTableId.
     *
     * El usuario debe escoger
     * la mesa manualmente.
     */
    selectedTableId = null;

    if (draftPeople != null && draftPeople.trim().isNotEmpty) {
      _peopleController.text = draftPeople.trim();
    }

    if (draftDate != null) {
      selectedDate = DateTime(draftDate.year, draftDate.month, draftDate.day);
    }

    if (draftTime != null) {
      selectedTime = draftTime;
    }
  }

  @override
  void dispose() {
    _peopleController.dispose();

    super.dispose();
  }

  /* ==========================================================
     CARGAR MESAS DISPONIBLES
     ========================================================== */

  Future<void> _loadTables() async {
    if (!mounted) return;

    setState(() {
      loadingTables = true;
      errorMessage = null;

      /*
       * Cada vez que cambia
       * fecha/hora quitamos
       * la selección anterior.
       */
      selectedTableId = null;
    });

    try {
      final auth = AuthScope.of(context);

      final token = auth.accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(401, 'La sesión no está disponible.');
      }

      /*
       * Fecha + hora exactas
       * seleccionadas por el usuario.
       */
      final ecuadorDateTime = buildEcuadorDateTime(selectedDate, selectedTime);

      /*
       * Convertimos Ecuador -> UTC
       * antes de enviarlo al backend.
       */
      final utcDateTime = ecuadorToUtc(ecuadorDateTime);

      /*
       * El backend devuelve
       * únicamente las mesas que
       * están disponibles para
       * esa fecha/hora.
       */
      final result = await ApiService.getAvailableTables(
        token,
        date: utcDateTime,
      );

      if (!mounted) return;

      setState(() {
        tables = result.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'numero': item['numero'],
            'capacidad': item['capacidad'],
            'disponible': item['disponible'],
          };
        }).toList();

        loadingTables = false;

        /*
         * Nunca dejamos una
         * mesa seleccionada
         * automáticamente.
         */
        selectedTableId = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        loadingTables = false;

        errorMessage = error.message;

        selectedTableId = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingTables = false;

        errorMessage = 'No fue posible cargar las mesas: $error';

        selectedTableId = null;
      });
    }
  }

  /* ==========================================================
     FECHA
     ========================================================== */

  Future<void> _pickDate() async {
    final today = ecuadorToday();

    final initialDate = selectedDate.isBefore(today) ? today : selectedDate;

    final picked = await showDatePicker(
      context: context,

      initialDate: initialDate,

      firstDate: today,

      lastDate: DateTime(today.year + 1, 12, 31),

      helpText: 'Selecciona la fecha',

      cancelText: 'Cancelar',

      confirmText: 'Aceptar',
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);

      /*
       * La mesa anterior ya
       * no se considera válida
       * hasta volver a consultar.
       */
      selectedTableId = null;
    });

    /*
     * Recargar mesas para
     * la nueva fecha.
     */
    await _loadTables();
  }

  /* ==========================================================
     HORA
     ========================================================== */

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,

      initialTime: selectedTime,

      helpText: 'Selecciona la hora',

      cancelText: 'Cancelar',

      confirmText: 'Aceptar',
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      selectedTime = picked;

      /*
       * Limpiamos mesa porque
       * cambió la hora.
       */
      selectedTableId = null;
    });

    /*
     * Recargar mesas para
     * la nueva hora.
     */
    await _loadTables();
  }

  /* ==========================================================
     FORMATO FECHA
     ========================================================== */

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /* ==========================================================
     FORMATO HORA
     ========================================================== */

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /* ==========================================================
     MESA SELECCIONADA
     ========================================================== */

  Map<String, dynamic>? _selectedTable() {
    if (selectedTableId == null) {
      return null;
    }

    for (final table in tables) {
      if (table['id'] == selectedTableId) {
        return table;
      }
    }

    return null;
  }

  /* ==========================================================
     CREAR RESERVA
     ========================================================== */

  Future<void> _submit() async {
    if (saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = AuthScope.of(context);

    final token = auth.accessToken;

    final userId = auth.userId;

    if (token == null || token.isEmpty) {
      _showMessage('La sesión no está disponible.', isError: true);

      return;
    }

    if (userId == null) {
      _showMessage('No fue posible identificar al usuario.', isError: true);

      return;
    }

    /*
     * OBLIGATORIO:
     * el usuario debe escoger
     * una mesa.
     */
    if (selectedTableId == null) {
      _showMessage('Selecciona una mesa.', isError: true);

      return;
    }

    final people = int.tryParse(_peopleController.text.trim());

    if (people == null || people <= 0) {
      _showMessage('Ingresa una cantidad válida de personas.', isError: true);

      return;
    }

    final table = _selectedTable();

    if (table == null) {
      _showMessage('La mesa seleccionada no está disponible.', isError: true);

      return;
    }

    final capacity = (table['capacidad'] as num?)?.toInt();

    if (capacity != null && people > capacity) {
      _showMessage(
        'La mesa seleccionada tiene capacidad para '
        '$capacity persona(s).',
        isError: true,
      );

      return;
    }

    final ecuadorDateTime = buildEcuadorDateTime(selectedDate, selectedTime);

    final now = ecuadorNow();

    if (ecuadorDateTime.isBefore(now)) {
      _showMessage(
        'La fecha y hora de la reserva deben ser futuras.',
        isError: true,
      );

      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await ApiService.createReservation(
        token: token,

        date: ecuadorToUtc(ecuadorDateTime),

        people: people,

        userId: userId,

        tableId: selectedTableId!,
      );

      if (!mounted) return;

      /*
       * Limpiar borrador.
       */
      CreateReservationPage.draftPeople = null;

      CreateReservationPage.draftDate = null;

      CreateReservationPage.draftTime = null;

      /*
       * IMPORTANTE:
       * también limpiamos mesa.
       */
      CreateReservationPage.draftTableId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada correctamente.')),
      );

      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;

      _showMessage('No fue posible crear la reserva: $error', isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  /* ==========================================================
     MENSAJE
     ========================================================== */

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  /* ==========================================================
     INTERFAZ
     ========================================================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),

            children: [
              /* ==================================================
                 ENCABEZADO
                 ================================================== */
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Row(
                        children: [
                          Icon(Icons.event_available, size: 28),

                          SizedBox(width: 10),

                          Text(
                            'Datos de la reserva',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Selecciona la fecha, hora, cantidad de personas y mesa.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /* PERSONAS */
              TextFormField(
                controller: _peopleController,

                keyboardType: TextInputType.number,

                textInputAction: TextInputAction.done,

                decoration: const InputDecoration(
                  labelText: 'Personas',

                  hintText: 'Ejemplo: 4',

                  prefixIcon: Icon(Icons.people_outline),

                  border: OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },

                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Ingresa la cantidad de personas.';
                  }

                  final number = int.tryParse(text);

                  if (number == null || number <= 0) {
                    return 'Ingresa una cantidad válida.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              /* FECHA */
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),

                  title: const Text('Fecha'),

                  subtitle: Text(_formatDate(selectedDate)),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: saving ? null : _pickDate,
                ),
              ),

              const SizedBox(height: 10),

              /* HORA */
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time_outlined),

                  title: const Text('Hora'),

                  subtitle: Text(_formatTime(selectedTime)),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: saving ? null : _pickTime,
                ),
              ),

              const SizedBox(height: 16),

              /* ==================================================
                 MESAS
                 ================================================== */
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Selecciona una mesa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (!loadingTables)
                    IconButton(
                      tooltip: 'Actualizar mesas',
                      onPressed: saving ? null : _loadTables,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Disponibles para ${_formatDate(selectedDate)} a las ${_formatTime(selectedTime)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),

              const SizedBox(height: 8),

              if (loadingTables)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),

                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 44,
                          color: Colors.red,
                        ),

                        const SizedBox(height: 10),

                        Text(errorMessage!, textAlign: TextAlign.center),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _loadTables,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recargar mesas'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (tables.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        const Icon(Icons.table_restaurant_outlined, size: 48),

                        const SizedBox(height: 10),

                        const Text(
                          'No hay mesas disponibles para esta fecha y hora.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _loadTables,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...tables.map((table) {
                  final rawId = table['id'];

                  final id = rawId is num
                      ? rawId.toInt()
                      : int.tryParse(rawId?.toString() ?? '');

                  final numero = table['numero']?.toString() ?? 'Sin nombre';

                  final capacidad = (table['capacidad'] as num?)?.toInt() ?? 0;

                  if (id == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),

                    child: Card(
                      clipBehavior: Clip.antiAlias,

                      child: RadioListTile<int>(
                        value: id,

                        /*
                           * Aquí solo se
                           * muestra seleccionado
                           * después de que el
                           * usuario pulse una mesa.
                           */
                        groupValue: selectedTableId,

                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  selectedTableId = value;
                                });
                              },

                        title: Text(
                          'Mesa $numero',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text('Capacidad: $capacidad persona(s)'),

                        secondary: const Icon(Icons.table_restaurant_outlined),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              /* ==================================================
                 RESUMEN
                 ================================================== */
              if (selectedTableId != null)
                Card(
                  color: AppColors.primaryLight.withValues(alpha: 0.08),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Resumen',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text('Fecha: ${_formatDate(selectedDate)}'),

                        Text('Hora: ${_formatTime(selectedTime)}'),

                        Text(
                          'Personas: ${_peopleController.text.isEmpty ? '-' : _peopleController.text}',
                        ),

                        Text('Mesa: ${_selectedTable()?['numero'] ?? '-'}'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              /* ==================================================
                 CREAR
                 ================================================== */
              SizedBox(
                height: 52,

                child: ElevatedButton.icon(
                  onPressed: saving ? null : _submit,

                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),

                  label: Text(saving ? 'Creando reserva...' : 'Crear reserva'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
