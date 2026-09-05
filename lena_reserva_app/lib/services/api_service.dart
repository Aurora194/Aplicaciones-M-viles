import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.fieldErrors = const {}});
  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;
  @override
  String toString() => message;
}

class ApiService {
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

  static Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  static Future<Map<String, dynamic>> healthCheck() async {
    return _decode(await http.get(Uri.parse('$baseUrl/api/health')));
  }

  static Future<Map<String, dynamic>> login(String correo, String password) async {
    return _decode(await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    ));
  }

  static Future<Map<String, dynamic>> registerUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    return _decode(await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'apellido': apellido, 'correo': correo, 'telefono': telefono, 'password': password}),
    ));
  }

  static Future<List<Reservation>> getReservations(String token) async {
    final body = _decode(await http.get(Uri.parse('$baseUrl/api/reservas'), headers: _auth(token)));
    return (body['data'] as List<dynamic>? ?? const []).map((item) => Reservation.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<Reservation> getReservation(String token, int id) async {
    final body = _decode(await http.get(Uri.parse('$baseUrl/api/reservas/$id'), headers: _auth(token)));
    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<List<Map<String, dynamic>>> getAvailableTables(String token) async {
    final body = _decode(await http.get(Uri.parse('$baseUrl/api/mesas/disponibles'), headers: _auth(token)));
    return (body['data'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  static Future<List<Map<String, dynamic>>> getUsers(String token) async {
    final body = _decode(await http.get(Uri.parse('$baseUrl/api/users'), headers: _auth(token)));
    return (body['data'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  static Future<Reservation> createReservation({
    required String token,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,
  }) async {
    final body = _decode(await http.post(
      Uri.parse('$baseUrl/api/reservas'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'fecha': date.toUtc().toIso8601String(), 'personas': people, 'usuarioId': userId, 'mesaId': tableId}),
    ));
    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<Reservation> updateReservation({
    required String token,
    required int id,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,
  }) async {
    final body = _decode(await http.put(
      Uri.parse('$baseUrl/api/reservas/$id'),
      headers: {..._auth(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'fecha': date.toUtc().toIso8601String(), 'personas': people, 'usuarioId': userId, 'mesaId': tableId}),
    ));
    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteReservation({required String token, required int id}) async {
    _decode(await http.delete(Uri.parse('$baseUrl/api/reservas/$id'), headers: _auth(token)));
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final fields = <String, String>{};
      final errors = body['errors'];
      if (errors is List) {
        for (final error in errors) {
          if (error is Map && error['path'] != null && error['message'] != null) fields[error['path'].toString()] = error['message'].toString();
        }
      } else if (errors is Map) {
        errors.forEach((key, value) => fields[key] = value.toString());
      }
      throw ApiException(response.statusCode, body['message']?.toString() ?? 'No se pudo completar la operación.', fieldErrors: fields);
    }
    return body;
  }
}
