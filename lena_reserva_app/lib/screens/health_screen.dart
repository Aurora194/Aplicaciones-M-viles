import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_state_view.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  AppViewState state = AppViewState.loading;

  String mensaje = 'Comprobando conexión...';

  @override
  void initState() {
    super.initState();
    verificarBackend();
  }

  Future<void> verificarBackend() async {
    setState(() {
      state = AppViewState.loading;
      mensaje = 'Comprobando conexión...';
    });

    try {
      final respuesta = await ApiService.healthCheck();

      setState(() {
        state = AppViewState.success;
        mensaje =
            respuesta['message'] ??
            'Leña Reserva API funcionando correctamente';
      });
    } catch (e) {
      setState(() {
        state = AppViewState.error;
        mensaje = 'No fue posible conectar con el servidor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leña Reserva App')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppStateView(
              state: state,
              message: mensaje,
              onRetry: verificarBackend,
              child: _buildSuccess(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

          Semantics(
            label: 'Restaurante Leña Steak House',
            image: true,
            child: const Icon(Icons.restaurant, size: 64),
          ),

          const SizedBox(height: 24),

          Text(
            'Leña Reserva App',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            mensaje,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Verificar servidor',
            icon: Icons.refresh,
            onPressed: verificarBackend,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
