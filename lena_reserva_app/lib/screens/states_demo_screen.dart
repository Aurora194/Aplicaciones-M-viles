import 'package:flutter/material.dart';

import '../widgets/app_state_view.dart';
import '../widgets/app_button.dart';

class StatesDemoScreen extends StatefulWidget {
  const StatesDemoScreen({super.key});

  @override
  State<StatesDemoScreen> createState() => _StatesDemoScreenState();
}

class _StatesDemoScreenState extends State<StatesDemoScreen> {
  AppViewState state = AppViewState.loading;

  void cambiarEstado(AppViewState nuevoEstado) {
    setState(() {
      state = nuevoEstado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estados del componente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AppStateView(
                  state: state,
                  message: state == AppViewState.empty
                      ? 'No hay información disponible.'
                      : state == AppViewState.error
                      ? 'No fue posible cargar la información.'
                      : null,
                  onRetry: () {
                    cambiarEstado(AppViewState.loading);
                  },
                  child: const Text(
                    'Información cargada correctamente.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            AppButton(
              label: 'Cargando',
              onPressed: () {
                cambiarEstado(AppViewState.loading);
              },
              icon: Icons.hourglass_empty,
            ),

            const SizedBox(height: 8),

            AppButton(
              label: 'Vacío',
              onPressed: () {
                cambiarEstado(AppViewState.empty);
              },
              icon: Icons.inbox_outlined,
            ),

            const SizedBox(height: 8),

            AppButton(
              label: 'Error',
              onPressed: () {
                cambiarEstado(AppViewState.error);
              },
              icon: Icons.error_outline,
            ),

            const SizedBox(height: 8),

            AppButton(
              label: 'Éxito',
              onPressed: () {
                cambiarEstado(AppViewState.success);
              },
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}
