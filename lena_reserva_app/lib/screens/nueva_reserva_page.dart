import 'package:flutter/material.dart';

import '../design/app_spacing.dart';

class NuevaReservaPage extends StatefulWidget {
  const NuevaReservaPage({super.key});

  @override
  State<NuevaReservaPage> createState() => _NuevaReservaPageState();
}

class _NuevaReservaPageState extends State<NuevaReservaPage> {
  final _formKey = GlobalKey<FormState>();

  final _personasController = TextEditingController();

  int? _usuarioId;
  int? _mesaId;
  DateTime? _fecha;

  bool _guardando = false;

  @override
  void dispose() {
    _personasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2030),
    );

    if (seleccionada != null) {
      setState(() {
        _fecha = seleccionada;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora != null) {
      final fechaBase = _fecha ?? DateTime.now();

      setState(() {
        _fecha = DateTime(
          fechaBase.year,
          fechaBase.month,
          fechaBase.day,
          hora.hour,
          hora.minute,
        );
      });
    }
  }

  String _formatearFecha() {
    if (_fecha == null) {
      return 'Seleccionar fecha';
    }

    final dia = _fecha!.day.toString().padLeft(2, '0');
    final mes = _fecha!.month.toString().padLeft(2, '0');
    final anio = _fecha!.year;

    return '$dia/$mes/$anio';
  }

  String _formatearHora() {
    if (_fecha == null) {
      return 'Seleccionar hora';
    }

    final hora = _fecha!.hour.toString().padLeft(2, '0');
    final minuto = _fecha!.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  Future<void> _crearReserva() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usuarioId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un usuario')));
      return;
    }

    if (_mesaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione una mesa')));
      return;
    }

    if (_fecha == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione fecha y hora')));
      return;
    }

    setState(() {
      _guardando = true;
    });

    /*
     * PASO 3.3:
     * Aquí conectaremos ApiService con:
     *
     * POST /api/reservas
     *
     * enviando:
     *
     * {
     *   "fecha": _fecha!.toUtc().toIso8601String(),
     *   "personas": int.parse(_personasController.text),
     *   "usuarioId": _usuarioId,
     *   "mesaId": _mesaId
     * }
     */

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _guardando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario validado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear nueva reserva',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                DropdownButtonFormField<int>(
                  initialValue: _usuarioId,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Usuario #1')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _usuarioId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione un usuario';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                DropdownButtonFormField<int>(
                  initialValue: _mesaId,
                  decoration: const InputDecoration(
                    labelText: 'Mesa',
                    prefixIcon: Icon(Icons.table_restaurant_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Mesa #1')),
                    DropdownMenuItem(value: 2, child: Text('Mesa #2')),
                    DropdownMenuItem(value: 3, child: Text('Mesa #3')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _mesaId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione una mesa';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _personasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de personas',
                    prefixIcon: Icon(Icons.people_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el número de personas';
                    }

                    final personas = int.tryParse(value);

                    if (personas == null) {
                      return 'Ingrese un número válido';
                    }

                    if (personas <= 0) {
                      return 'Debe ser mayor que 0';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _guardando ? null : _seleccionarFecha,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_formatearFecha()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _guardando ? null : _seleccionarHora,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(_formatearHora()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _crearReserva,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _guardando ? 'Creando reserva...' : 'Crear reserva',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
