import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';

enum ReservationStatus { confirmed, pending, cancelled }

extension ReservationStatusLabel on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.cancelled:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.cancelled:
        return AppColors.danger;
    }
  }
}

class ReservationItem {
  const ReservationItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.guests,
    required this.status,
    this.subtitle,
  });

  final int id;
  final String title;
  final String date;
  final String time;
  final int guests;
  final ReservationStatus status;
  final String? subtitle;
}

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.item, this.onTap});

  final ReservationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: item.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    item.status.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: item.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(item.date),
                const SizedBox(width: AppSpacing.md),
                const Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(item.time),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${item.guests} personas'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
