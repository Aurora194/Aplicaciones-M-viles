class Reservation {
  const Reservation({
    required this.id,
    required this.date,
    required this.people,
    required this.status,
    required this.tableId,
    this.tableNumber,
    this.clientName,
  });

  final int id;
  final DateTime date;
  final int people;
  final String status;
  final int tableId;
  final String? tableNumber;
  final String? clientName;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final table = json['mesa'] is Map
        ? Map<String, dynamic>.from(json['mesa'] as Map)
        : null;

    final user = json['usuario'] is Map
        ? Map<String, dynamic>.from(json['usuario'] as Map)
        : null;

    return Reservation(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      date: DateTime.parse(json['fecha'].toString()),
      people: json['personas'] is num
          ? (json['personas'] as num).toInt()
          : int.tryParse(json['personas']?.toString() ?? '') ?? 0,
      status: json['estado']?.toString().trim().toUpperCase() ?? 'PENDIENTE',
      tableId: json['mesaId'] is num
          ? (json['mesaId'] as num).toInt()
          : int.tryParse(json['mesaId']?.toString() ?? '') ?? 0,
      tableNumber: table?['numero']?.toString(),
      clientName: user == null ? null : _buildClientName(user),
    );
  }

  static String? _buildClientName(Map<String, dynamic> user) {
    final nombre = user['nombre']?.toString().trim() ?? '';

    final apellido = user['apellido']?.toString().trim() ?? '';

    final nombreCompleto = '$nombre $apellido'.trim();

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    final correo = user['correo']?.toString().trim();

    return correo?.isNotEmpty == true ? correo : null;
  }
}
