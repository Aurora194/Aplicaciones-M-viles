import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

enum AppViewState {
  loading,
  empty,
  error,
  success,
}

class AppStateView extends StatelessWidget {
  final AppViewState state;
  final String? message;
  final VoidCallback? onRetry;
  final Widget? child;

  const AppStateView({
    super.key,
    required this.state,
    this.message,
    this.onRetry,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppViewState.loading:
        return Semantics(
          label: 'Cargando información',
          liveRegion: true,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        );

      case AppViewState.empty:
        return Semantics(
          liveRegion: true,
          label: message ?? 'No hay información disponible',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                message ?? 'No hay información disponible.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ),
          ),
        );

      case AppViewState.error:
        return Semantics(
          liveRegion: true,
          label: message ?? 'Ocurrió un error',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.errorText,
                    semanticLabel: 'Error',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message ?? 'Ocurrió un error.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (onRetry != null)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.md,
                            ),
                          ),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case AppViewState.success:
        return child ?? const SizedBox.shrink();
    }
  }
}