import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'auth/auth_scope.dart';

class MesasPage extends StatefulWidget {
  const MesasPage({super.key});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  bool _loading = true;
  bool _cargandoInicial = true;

  String? _error;

  List<Map<String, dynamic>> _mesas = [];

  int _requestId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMesas(esCargaInicial: true);
      }
    });
  }

  Future<void> _loadMesas({bool esCargaInicial = false}) async {
    if (!mounted) return;

    final int requestActual = ++_requestId;

    final auth = AuthScope.of(context);
    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');

      return;
    }

    setState(() {
      _error = null;

      if (esCargaInicial || _mesas.isEmpty) {
        _loading = true;
      }

      _cargandoInicial = esCargaInicial;
    });

    try {
      final mesas = await ApiService.getTables(token);

      if (!mounted) return;

      // Ignorar respuestas antiguas si hubo otra petición posterior.
      if (requestActual != _requestId) return;

      setState(() {
        _mesas = mesas;
        _loading = false;
        _cargandoInicial = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (requestActual != _requestId) return;

      if (error.statusCode == 401) {
        await auth.signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');

        return;
      }

      setState(() {
        _loading = false;
        _cargandoInicial = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      if (requestActual != _requestId) return;

      setState(() {
        _loading = false;
        _cargandoInicial = false;
        _error = 'No fue posible cargar las mesas.\n$error';
      });
    } finally {
      if (!mounted) return;

      if (requestActual == _requestId) {
        if (_loading) {
          setState(() {
            _loading = false;
            _cargandoInicial = false;
          });
        }
      }
    }
  }

  Future<void> _showTableDialog({Map<String, dynamic>? mesa}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return MesaDialog(mesa: mesa);
      },
    );

    if (!mounted) return;

    if (result == true) {
      await _loadMesas();
    }
  }

  Future<void> _deleteTable(Map<String, dynamic> mesa) async {
    final id = (mesa['id'] as num).toInt();
    final numero = mesa['numero']?.toString() ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar mesa'),
          content: Text('¿Desea eliminar la mesa "$numero"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final auth = AuthScope.of(context);
    final token = auth.accessToken;

    if (token == null || token.isEmpty) return;

    try {
      await ApiService.deleteTable(token: token, id: id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa eliminada correctamente.')),
      );

      await _loadMesas();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible eliminar la mesa.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.userRole != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Mesas')),
        body: const Center(
          child: Text('No tiene permisos para administrar mesas.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar mesas')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTableDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva mesa'),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Primera carga sin datos.
    if (_cargandoInicial && _mesas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si existe error pero ya tenemos mesas,
    // mostramos las mesas y no dejamos la pantalla
    // atrapada en "Cargando".
    if (_error != null && _mesas.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMesas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.errorContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._buildMesaCards(),
          ],
        ),
      );
    }

    if (_error != null && _mesas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  _loadMesas(esCargaInicial: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mesas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMesas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No existen mesas registradas.')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadMesas,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            children: _buildMesaCards(),
          ),
        ),

        // Indicador pequeño cuando se actualizan
        // mesas que ya están visibles.
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  List<Widget> _buildMesaCards() {
    return _mesas.map((mesa) {
      final numero = mesa['numero']?.toString() ?? '-';

      final capacidad = mesa['capacidad']?.toString() ?? '-';

      final disponible = mesa['disponible'] == true;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(numero),
              ),
            ),
          ),

          title: Text(
            'Mesa $numero',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          subtitle: Text(
            'Capacidad: $capacidad personas\n'
            'Estado: '
            '${disponible ? 'Disponible' : 'No disponible'}',
          ),

          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'editar') {
                _showTableDialog(mesa: mesa);
              } else if (value == 'eliminar') {
                _deleteTable(mesa);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),

          isThreeLine: true,
        ),
      );
    }).toList();
  }
}

// ============================================================
// DIÁLOGO CREAR / EDITAR MESA
// ============================================================

class MesaDialog extends StatefulWidget {
  final Map<String, dynamic>? mesa;

  const MesaDialog({super.key, this.mesa});

  @override
  State<MesaDialog> createState() => _MesaDialogState();
}

class _MesaDialogState extends State<MesaDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numeroController;
  late final TextEditingController _capacidadController;

  bool _disponible = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _numeroController = TextEditingController(
      text: widget.mesa?['numero']?.toString() ?? '',
    );

    _capacidadController = TextEditingController(
      text: widget.mesa?['capacidad']?.toString() ?? '',
    );

    _disponible = widget.mesa?['disponible'] == true;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final numero = _numeroController.text.trim();

    final capacidad = int.tryParse(_capacidadController.text.trim());

    if (capacidad == null || capacidad <= 0) {
      return;
    }

    final auth = AuthScope.of(context);
    final token = auth.accessToken;

    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pop(context, false);
      }
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      if (widget.mesa == null) {
        await ApiService.createTable(
          token: token,
          numero: numero,
          capacidad: capacidad,
          disponible: _disponible,
        );
      } else {
        await ApiService.updateTable(
          token: token,
          id: (widget.mesa!['id'] as num).toInt(),
          numero: numero,
          capacidad: capacidad,
          disponible: _disponible,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar la mesa.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editar = widget.mesa != null;

    return AlertDialog(
      title: Text(editar ? 'Editar mesa' : 'Crear nueva mesa'),

      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _numeroController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Número o nombre de mesa',
                hintText: 'Ej: 7, VIP 1, Salón VIP',
                prefixIcon: Icon(Icons.table_restaurant_outlined),
              ),
              validator: (value) {
                final numero = value?.trim() ?? '';

                if (numero.isEmpty) {
                  return 'Ingrese un número o nombre de mesa';
                }

                if (numero.length > 50) {
                  return 'Máximo 50 caracteres';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _capacidadController,
              keyboardType: TextInputType.number,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Capacidad',
                hintText: 'Ej: 2, 4, 6',
                prefixIcon: Icon(Icons.people_outline),
              ),
              validator: (value) {
                final capacidad = int.tryParse(value?.trim() ?? '');

                if (capacidad == null || capacidad <= 0) {
                  return 'Ingrese una capacidad válida';
                }

                return null;
              },
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible'),
              value: _disponible,
              onChanged: _guardando
                  ? null
                  : (value) {
                      setState(() {
                        _disponible = value;
                      });
                    },
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: _guardando
              ? null
              : () {
                  Navigator.pop(context, false);
                },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editar ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
