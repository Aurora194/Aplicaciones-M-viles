import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import 'reservation_card.dart';

enum ReservationListState {
  loading,
  empty,
  error,
  success,
}

class ReservationList extends StatelessWidget {
  const ReservationList({
    super.key,
    required this.state,
    this.reservations = const [],
    this.errorMessage,
    this.onRetry,
  });

  final ReservationListState state;
  final List<ReservationItem> reservations;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ReservationListState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(),
          ),
        );
      case ReservationListState.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 52, color: AppColors.primaryLight),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No hay reservas por el momento',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      case ReservationListState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 52, color: AppColors.danger),
                const SizedBox(height: AppSpacing.md),
                Text(
                  errorMessage ?? 'No se pudo cargar la información',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
          ),
        );
      case ReservationListState.success:
        if (reservations.isEmpty) {
          return const Center(
            child: Text('Sin reservas disponibles'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: reservations.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => ReservationCard(item: reservations[index]),
        );
    }
  }
}
