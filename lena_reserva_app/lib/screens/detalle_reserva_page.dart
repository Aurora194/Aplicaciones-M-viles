import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';

class DetalleReservaPage extends StatelessWidget {
  const DetalleReservaPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de reserva #$id',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de la reserva',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const _DetailRow(
                      icon: Icons.table_restaurant_outlined,
                      label: 'Mesa',
                      value: 'Mesa para 4',
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const _DetailRow(
                      icon: Icons.event_outlined,
                      label: 'Fecha',
                      value: '15 Sep 2026',
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const _DetailRow(
                      icon: Icons.access_time_outlined,
                      label: 'Hora',
                      value: '20:30',
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const _DetailRow(
                      icon: Icons.people_alt_outlined,
                      label: 'Personas',
                      value: '4 personas',
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const _DetailRow(
                      icon: Icons.info_outline,
                      label: 'Estado',
                      value: 'Confirmada',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar reserva'),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar reserva'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryLight),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
