import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'login_page.dart';

void main() {
  runApp(const LenaReservaApp());
}

class LenaReservaApp extends StatelessWidget {
  const LenaReservaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leña Reserva',
      home: const LoginPage(),
    );
  }
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  String mensaje = 'Comprobando conexión...';

  @override
  void initState() {
    super.initState();
    verificarBackend();
  }

  Future<void> verificarBackend() async {
    try {
      final respuesta = await ApiService.healthCheck();

      setState(() {
        mensaje = respuesta['message'] ?? 'Backend conectado';
      });
    } catch (e) {
      setState(() {
        mensaje = 'Error de conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leña Reserva')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Leña Reserva App',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
