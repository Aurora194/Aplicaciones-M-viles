import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'models/reservation.dart';
import 'services/api_service.dart';
import 'state/auth_controller.dart';

enum ReservationLoadState { loading, empty, error, success }

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
          arguments: '/app/reservas',
        );
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      state = ReservationLoadState.loading;
      errorMessage = null;
    });
    try {
      final auth = AuthScope.of(context);
      final result = await ApiService.getReservations(auth.accessToken!);
      if (!mounted) return;
      setState(() {
        reservations = result;
        state = result.isEmpty
            ? ReservationLoadState.empty
            : ReservationLoadState.success;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();
        if (mounted)
          Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: '/app/reservas',
          );
        return;
      }
      setState(() {
        state = ReservationLoadState.error;
        errorMessage = error.statusCode == 403
            ? 'Acceso denegado.'
            : error.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          state = ReservationLoadState.error;
          errorMessage = 'No se pudo conectar con el backend.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F7F6),
    appBar: AppBar(
      title: const Text(
        'Reservas',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Filtrar reservas',
          onPressed: () {},
          icon: const Icon(Icons.filter_list_outlined),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            await AuthScope.of(context).signOut();
            if (context.mounted)
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
      ReservationLoadState.empty => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
          children: [
            Row(
              children: [
                const Expanded(
                  child: _SummaryTile(
                    label: 'Reservas',
                    value: '0',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: _SummaryTile(
                    label: 'Confirmadas',
                    value: '0',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ReservationActions(
              onView: _load,
              onCreate: () =>
                  Navigator.pushNamed(context, '/app/reservas/nueva'),
            ),
            const SizedBox(height: 80),
            const Center(child: Text('No hay reservas registradas.')),
          ],
        ),
      ),
      ReservationLoadState.error => _ErrorView(
        message: errorMessage!,
        onRetry: _load,
      ),
      ReservationLoadState.success => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
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
                    value:
                        '${reservations.where((r) => r.status == 'CONFIRMADA').length}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ReservationActions(
              onView: _load,
              onCreate: () =>
                  Navigator.pushNamed(context, '/app/reservas/nueva'),
            ),
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
                  if (mounted && auth.isAuthenticated) {
                    await _load();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    },
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _ReservationActions extends StatelessWidget {
  const _ReservationActions({required this.onView, required this.onCreate});

  final VoidCallback onView;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Ver reservas'),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nueva reserva'),
          ),
        ),
      ),
    ],
  );
}

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
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mesa ${item.tableNumber ?? item.tableId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.clientName ?? 'Reserva de mesa',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 10,
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

  String _month(int month) => const [
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

class _ReservationMeta extends StatelessWidget {
  const _ReservationMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.primaryLight),
      const SizedBox(width: 7),
      Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    ],
  );
}

class ReservationDetailPage extends StatefulWidget {
  const ReservationDetailPage({super.key, required this.id});
  final int id;
  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  late Future<Reservation> request;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final token = AuthScope.of(context).accessToken;
    if (token == null || token.isEmpty) {
      request = Future.error(const ApiException(401, 'Sesión no disponible.'));
    } else {
      request = ApiService.getReservation(token, widget.id);
    }
    _initialized = true;
  }

  Future<void> _cancel(Reservation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text('¿Desea cancelar la reserva #${item.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteReservation(
        token: AuthScope.of(context).accessToken!,
        id: item.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reserva cancelada.')));
        setState(() {
          request = ApiService.getReservation(
            AuthScope.of(context).accessToken!,
            widget.id,
          );
        });
      }
    } on ApiException catch (error) {
      if (mounted)
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
    var editDate = item.date;
    var editTime = TimeOfDay.fromDateTime(item.date);
    var savingEdit = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
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
                    return number == null || number < 1 || number > 20
                        ? 'Ingrese entre 1 y 20 personas.'
                        : null;
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
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDate: editDate,
                          );
                          if (picked != null && dialogContext.mounted) {
                            setDialogState(
                              () => editDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                editTime.hour,
                                editTime.minute,
                              ),
                            );
                          }
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
                          if (picked != null && dialogContext.mounted) {
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
                          }
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: savingEdit
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => savingEdit = true);
                      try {
                        await ApiService.updateReservation(
                          token: auth.accessToken!,
                          id: item.id,
                          date: editDate,
                          people: int.parse(peopleController.text),
                          userId: auth.userId ?? 0,
                          tableId: item.tableId,
                        );
                        if (dialogContext.mounted)
                          Navigator.pop(dialogContext, true);
                      } on ApiException catch (error) {
                        if (pageContext.mounted)
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        if (dialogContext.mounted)
                          setDialogState(() => savingEdit = false);
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    peopleController.dispose();
    if (result == true && mounted) {
      setState(() {
        request = ApiService.getReservation(
          AuthScope.of(context).accessToken!,
          widget.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de reserva')),
    body: FutureBuilder<Reservation>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return const _ErrorView(message: 'No se pudo cargar el detalle.');
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Detalle de reserva #${item.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          '${item.date.day} ${_month(item.date.month)} ${item.date.year}',
                    ),
                    _DetailRow(
                      icon: Icons.access_time_outlined,
                      label: 'Hora',
                      value:
                          '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
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
            OutlinedButton.icon(
              onPressed: () => _cancel(item),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar reserva'),
            ),
          ],
        );
      },
    ),
  );
  String _month(int month) => const [
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
  Widget build(BuildContext context) => Padding(
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

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({super.key});
  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  static int? _draftUserId;
  static int? _draftTableId;
  static String _draftPeople = '';
  static DateTime? _draftDate;
  static TimeOfDay? _draftTime;

  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final peopleController = TextEditingController();
  List<Map<String, dynamic>> tables = const [];
  List<Map<String, dynamic>> users = const [];
  int? selectedUserId;
  int? selectedTableId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool saving = false;
  bool loadingTables = true;
  bool loadingUsers = true;
  Map<String, String> serverErrors = {};

  @override
  void initState() {
    super.initState();
    selectedUserId = _draftUserId;
    selectedTableId = _draftTableId;
    selectedDate = _draftDate;
    selectedTime = _draftTime;
    peopleController.text = _draftPeople;
    _syncDateController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTables();
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    try {
      final auth = AuthScope.of(context);
      final result = await ApiService.getUsers(auth.accessToken!);
      if (mounted) {
        final validUsers = result
            .where((user) => user['id'] is num)
            .map((user) => Map<String, dynamic>.from(user))
            .toList(growable: false);
        setState(() {
          users = validUsers;
          if (!validUsers.any(
            (user) => (user['id'] as num).toInt() == selectedUserId,
          )) {
            selectedUserId = null;
          }
          loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingUsers = false);
    }
  }

  Future<void> _loadTables() async {
    try {
      final auth = AuthScope.of(context);
      final result = await ApiService.getAvailableTables(auth.accessToken!);
      if (mounted) {
        final validTables = result
            .where((table) => table['id'] is num && table['numero'] != null)
            .map((table) => Map<String, dynamic>.from(table))
            .toList(growable: false);
        setState(() {
          tables = validTables;
          if (!validTables.any(
            (table) => (table['id'] as num).toInt() == selectedTableId,
          )) {
            selectedTableId = null;
          }
          loadingTables = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingTables = false);
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    peopleController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    _draftUserId = selectedUserId;
    _draftTableId = selectedTableId;
    _draftPeople = peopleController.text;
    _draftDate = selectedDate;
    _draftTime = selectedTime;
  }

  void _syncDateController() {
    if (selectedDate == null) {
      dateController.clear();
      return;
    }
    final time = selectedTime ?? const TimeOfDay(hour: 19, minute: 0);
    dateController.text = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      time.hour,
      time.minute,
    ).toIso8601String();
  }

  void _clearDraft() {
    _draftUserId = null;
    _draftTableId = null;
    _draftPeople = '';
    _draftDate = null;
    _draftTime = null;
  }

  String? _required(String? value, String field) =>
      value == null || value.trim().isEmpty ? '$field es obligatorio.' : null;
  Future<void> _submit() async {
    setState(() => serverErrors = {});
    if (!formKey.currentState!.validate()) return;
    final date = DateTime.tryParse(dateController.text.trim());
    final people = int.tryParse(peopleController.text.trim());
    final table = selectedTableId;
    if (date == null || people == null || table == null) return;
    setState(() => saving = true);
    try {
      final auth = AuthScope.of(context);
      await ApiService.createReservation(
        token: auth.accessToken!,
        date: date,
        people: people,
        userId: selectedUserId!,
        tableId: table,
      );
      if (!mounted) return;
      _clearDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada exitosamente.')),
      );
      Navigator.pushReplacementNamed(context, '/app/reservas');
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await AuthScope.of(context).signOut();
        if (mounted)
          Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: '/app/reservas/nueva',
          );
      } else if (error.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso denegado para crear reservas.')),
        );
      } else if (error.statusCode == 422) {
        setState(() => serverErrors = error.fieldErrors);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      selectedDate = picked;
      final time = selectedTime ?? const TimeOfDay(hour: 19, minute: 0);
      dateController.text = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      ).toIso8601String();
      _saveDraft();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      selectedTime = picked;
      final date = selectedDate ?? DateTime.now();
      dateController.text = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      ).toIso8601String();
      _saveDraft();
    });
  }

  String _dateLabel() => selectedDate == null
      ? 'Seleccionar fecha'
      : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';

  String _timeLabel() =>
      selectedTime == null ? 'Seleccionar hora' : selectedTime!.format(context);

  List<DropdownMenuItem<int>> _userItems() {
    final seen = <int>{};
    return users
        .where((user) {
          final id = (user['id'] as num?)?.toInt();
          return id != null && seen.add(id);
        })
        .map((user) {
          final id = (user['id'] as num).toInt();
          final name = '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'
              .trim();
          return DropdownMenuItem(
            value: id,
            child: Text(name.isEmpty ? user['correo'].toString() : name),
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
          return DropdownMenuItem(
            value: id,
            child: Text('Mesa ${table['numero']}'),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          DropdownButtonFormField<int>(
            key: ValueKey('user-${users.length}'),
            initialValue:
                users.any(
                  (user) => (user['id'] as num?)?.toInt() == selectedUserId,
                )
                ? selectedUserId
                : null,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
            ),
            hint: Text(
              loadingUsers ? 'Cargando usuarios...' : 'Seleccionar usuario',
            ),
            items: _userItems(),
            onChanged: loadingUsers
                ? null
                : (value) => setState(() {
                    selectedUserId = value;
                    _saveDraft();
                  }),
            validator: (value) =>
                value == null ? 'Seleccione un usuario.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey('table-${tables.length}'),
            initialValue:
                tables.any(
                  (table) => (table['id'] as num?)?.toInt() == selectedTableId,
                )
                ? selectedTableId
                : null,
            decoration: const InputDecoration(
              labelText: 'Mesa',
              prefixIcon: Icon(Icons.table_restaurant_outlined),
            ),
            hint: Text(
              loadingTables ? 'Cargando mesas...' : 'Seleccionar mesa',
            ),
            items: _tableItems(),
            onChanged: loadingTables
                ? null
                : (value) => setState(() {
                    selectedTableId = value;
                    _saveDraft();
                  }),
            validator: (value) =>
                value == null ? 'Seleccione una mesa disponible.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: peopleController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'Número de personas',
              prefixIcon: Icon(Icons.people_outline),
            ),
            validator: (value) {
              final required = _required(value, 'El número de personas');
              if (required != null) return required;
              final number = int.tryParse(value!);
              return number == null || number < 1 || number > 20
                  ? 'Ingrese entre 1 y 20 personas.'
                  : null;
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
            validator: (_) =>
                selectedDate == null ? 'Seleccione una fecha.' : null,
            builder: (field) => field.hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (serverErrors['fecha'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                serverErrors['fecha']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (serverErrors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                serverErrors.values.join('\n'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: saving ? null : _submit,
            icon: const Icon(Icons.check),
            label: saving
                ? const Text('Guardando...')
                : const Text('Crear reserva'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
