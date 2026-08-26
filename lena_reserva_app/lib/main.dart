import 'package:flutter/material.dart';

import 'screens/health_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LenaReservaApp());
}

class LenaReservaApp extends StatelessWidget {
  const LenaReservaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leña Reserva App',
      theme: AppTheme.light(),
      home: const HealthScreen(),
    );
  }
}
