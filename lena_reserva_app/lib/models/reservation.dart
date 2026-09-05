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
  final int? tableNumber;
  final String? clientName;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final table = json['mesa'] as Map<String, dynamic>?;
    final user = json['usuario'] as Map<String, dynamic>?;
    return Reservation(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['fecha'].toString()),
      people: (json['personas'] as num).toInt(),
      status: json['estado']?.toString() ?? 'PENDIENTE',
      tableId: (json['mesaId'] as num).toInt(),
      tableNumber: (table?['numero'] as num?)?.toInt(),
      clientName: user == null
          ? null
          : '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'.trim(),
    );
  }
}
