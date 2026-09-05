import 'package:flutter/material.dart';

import 'design/app_colors.dart';
import 'design/app_spacing.dart';
import 'state/auth_controller.dart';
import 'widgets/app_button.dart';
import 'widgets/reservation_card.dart';
import 'widgets/reservation_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  ReservationListState _state = ReservationListState.success;

  final List<ReservationItem> _reservations = const [
    ReservationItem(
      id: 1,
      title: 'Mesa para 4',
      subtitle: 'Evento familiar',
      date: '15 Sep 2026',
      time: '20:30',
      guests: 4,
      status: ReservationStatus.confirmed,
    ),
    ReservationItem(
      id: 2,
      title: 'Terraza VIP',
      subtitle: 'Cena romántica',
      date: '18 Sep 2026',
      time: '21:00',
      guests: 2,
      status: ReservationStatus.pending,
    ),
    ReservationItem(
      id: 3,
      title: 'Sala privada',
      subtitle: 'Reunión de trabajo',
      date: '22 Sep 2026',
      time: '18:15',
      guests: 6,
      status: ReservationStatus.cancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
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
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Reservas',
                          value: '12',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Confirmadas',
                          value: '9',
                          color: AppColors.success,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryTile(
                            label: 'Pendientes',
                            value: '3',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: isCompact ? double.infinity : 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Ver reservas',
                              onPressed: () => Navigator.pushNamed(context, '/app/reservas'),
                              icon: Icons.list_alt,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: 'Nueva reserva',
                              onPressed: () => Navigator.pushNamed(context, '/app/reservas/nueva'),
                              icon: Icons.add,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ReservationList(
                    state: _state,
                    reservations: _reservations,
                    onRetry: () {
                      setState(() => _state = ReservationListState.success);
                    },
                    onReservationTap: (reservation) {
                      Navigator.of(
                        context,
                      ).pushNamed('/app/reservas/${reservation.id}');
                    },
                  ),
                ),
              ],
            );
          },
        ),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
