import 'package:flutter/material.dart';

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
            child: CircularProgressIndicator(),
          ),
        );
      case AppViewState.empty:
        return Semantics(
          liveRegion: true,
          label: message ?? 'No hay información disponible',
          child: Center(
            child: Text(
              message ?? 'No hay información disponible.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      case AppViewState.error:
        return Semantics(
          liveRegion: true,
          label: message ?? 'Ocurrió un error',
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  semanticLabel: 'Error',
                ),
                const SizedBox(height: 16),
                Text(
                  message ?? 'Ocurrió un error.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (onRetry != null)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Reintentar'),
                    ),
                  ),
              ],
            ),
          ),
        );
      case AppViewState.success:
        return child ?? const SizedBox.shrink();
    }
  }
}
