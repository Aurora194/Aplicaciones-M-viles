import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/reservation.dart';

class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.message, {
    this.fieldErrors = const {},
  });

  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

// =========================================================
// RESPUESTA DE LA IA
// =========================================================

class AIResponse {
  const AIResponse({
    required this.answer,
    this.role,
    this.reservationDraft,
    this.availability,
  });

  final String answer;
  final String? role;

  final Map<String, dynamic>? reservationDraft;

  final AIAvailability? availability;
}

class AIAvailability {
  const AIAvailability({
    required this.fecha,
    required this.cantidad,
    required this.mesas,
  });

  final String? fecha;
  final int cantidad;
  final List<Map<String, dynamic>> mesas;

  factory AIAvailability.fromJson(Map<String, dynamic> json) {
    final rawMesas = json['mesas'];

    final mesas = rawMesas is List
        ? rawMesas
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return AIAvailability(
      fecha: json['fecha']?.toString(),
      cantidad:
          int.tryParse(json['cantidad']?.toString() ?? '') ?? mesas.length,
      mesas: mesas,
    );
  }
}

class ApiService {
  // =========================================================
  // DIRECCIONES DEL BACKEND
  // =========================================================

  /// Emulador Android:
  /// 10.0.2.2 apunta al localhost de la computadora.
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000';

  /// Teléfono físico conectado a la misma red que la PC.
  static const String physicalDeviceBaseUrl = 'http://192.168.1.3:3000';

  /// Permite sobrescribir la URL usando:
  ///
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.3:3000
  ///
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL que utilizará la aplicación.
  ///
  /// Android físico  -> 192.168.1.3:3000
  /// Android emulador -> 10.0.2.2:3000
  /// Web              -> 192.168.1.3:3000
  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return physicalDeviceBaseUrl;
    }

    if (Platform.isAndroid) {
      // Android físico y emulador:
      //
      // Por defecto usamos la IP de la PC para que también
      // funcione en el teléfono físico.
      //
      // Para el emulador también podemos ejecutar con:
      //
      // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
      //
      return physicalDeviceBaseUrl;
    }

    return physicalDeviceBaseUrl;
  }

  // =========================================================
  // HEADERS
  // =========================================================

  static Map<String, String> _authorizationHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  // =========================================================
  // HEALTH
  // =========================================================

  static Future<Map<String, dynamic>> healthCheck() async {
    final url = '$baseUrl/api/health';

    print('========================================');
    print('API HEALTH');
    print('URL: $url');
    print('========================================');

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    return _decode(response);
  }

  // =========================================================
  // AUTENTICACIÓN
  // =========================================================

  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    final url = '$baseUrl/api/auth/login';

    print('========================================');
    print('LOGIN');
    print('URL: $url');
    print('Correo: $correo');
    print('========================================');

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'correo': correo, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: ${response.body}');

    return _decode(response);
  }

  static Future<Map<String, dynamic>> forgotPassword(String correo) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/forgot-password'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'correo': correo.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    print(
      'FORGOT PASSWORD STATUS: '
      '${response.statusCode}',
    );

    print(
      'FORGOT PASSWORD BODY: '
      '${response.body}',
    );

    print(
      'FORGOT PASSWORD HEADERS: '
      '${response.headers}',
    );

    return _decode(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/reset-password'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'correo': correo.trim(),
            'codigo': codigo.trim(),
            'nuevaPassword': nuevaPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _decode(response);
  }

  static Future<Map<String, dynamic>> registerUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'nombre': nombre,
            'apellido': apellido,
            'correo': correo,
            'telefono': telefono,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return _decode(response);
  }

  // =========================================================
  // RESERVAS
  // =========================================================

  static Future<List<Reservation>> getReservations(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/reservas'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Reservation.fromJson)
        .toList();
  }

  static Future<Reservation> getReservation(String token, int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<Reservation> createReservation({
    required String token,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/reservas'),
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'fecha': date.toUtc().toIso8601String(),
            'personas': people,
            'usuarioId': userId,
            'mesaId': tableId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final rawData = body['data'];

    if (rawData is! Map) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió los datos de la reserva creada.',
      );
    }

    return Reservation.fromJson(Map<String, dynamic>.from(rawData));
  }

  static Future<Reservation> updateReservation({
    required String token,
    required int id,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'fecha': date.toUtc().toIso8601String(),
            'personas': people,
            'usuarioId': userId,
            'mesaId': tableId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<Reservation> updateReservationStatus({
    required String token,
    required int id,
    required String status,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'estado': status}),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return Reservation.fromJson(body['data'] as Map<String, dynamic>);
  }

  // =========================================================
  // MESAS DISPONIBLES
  // =========================================================

  static Future<List<Map<String, dynamic>>> getAvailableTables(
    String token, {
    DateTime? date,
  }) async {
    final uri = Uri.parse('$baseUrl/api/mesas/disponibles');

    final finalUri = date == null
        ? uri
        : uri.replace(
            queryParameters: {'fecha': date.toUtc().toIso8601String()},
          );

    print(
      'CONSULTANDO MESAS DISPONIBLES: '
      '$finalUri',
    );

    final response = await http
        .get(
          finalUri,
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    print(
      'RESPUESTA MESAS DISPONIBLES: '
      '${response.statusCode} ${response.body}',
    );

    final body = _decode(response);

    final data = body['data'];

    if (data is! List) {
      throw ApiException(
        response.statusCode,
        'La respuesta de disponibilidad no contiene una lista de mesas.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =========================================================
  // MESAS - ADMINISTRACIÓN
  // =========================================================

  static Future<List<Map<String, dynamic>>> getTables(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/mesas?limit=100&order=asc'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<Map<String, dynamic>> createTable({
    required String token,
    required String numero,
    required int capacidad,
    bool disponible = true,
  }) async {
    final nombreMesa = numero.trim();

    if (nombreMesa.isEmpty) {
      throw const ApiException(
        422,
        'El número o nombre de mesa es obligatorio.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/mesas'),
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'numero': nombreMesa,
            'capacidad': capacidad,
            'disponible': disponible,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return body['mesa'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateTable({
    required String token,
    required int id,
    required String numero,
    required int capacidad,
    required bool disponible,
  }) async {
    final nombreMesa = numero.trim();

    if (nombreMesa.isEmpty) {
      throw const ApiException(
        422,
        'El número o nombre de mesa es obligatorio.',
      );
    }

    final response = await http
        .put(
          Uri.parse('$baseUrl/api/mesas/$id'),
          headers: {
            ..._authorizationHeaders(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'numero': nombreMesa,
            'capacidad': capacidad,
            'disponible': disponible,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return body['mesa'] as Map<String, dynamic>;
  }

  static Future<void> deleteTable({
    required String token,
    required int id,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/api/mesas/$id'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    _decode(response);
  }

  // =========================================================
  // USUARIOS
  // =========================================================

  static Future<List<Map<String, dynamic>>> getUsers(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/users'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // =========================================================
  // INTELIGENCIA ARTIFICIAL
  // =========================================================

  static Future<AIResponse> askAI({
    required String token,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/ai/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ..._authorizationHeaders(token),
          },
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 30));

    final body = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        body['message']?.toString() ?? 'No se pudo comunicar con la IA.',
      );
    }

    Map<String, dynamic>? draft;

    final rawDraft = body['reservationDraft'];

    if (rawDraft is Map) {
      draft = Map<String, dynamic>.from(rawDraft);
    }

    AIAvailability? availability;

    final rawAvailability = body['availability'];

    if (rawAvailability is Map) {
      availability = AIAvailability.fromJson(
        Map<String, dynamic>.from(rawAvailability),
      );
    }

    return AIResponse(
      answer:
          body['answer']?.toString() ??
          'No se recibió una respuesta del asistente.',
      role: body['role']?.toString(),
      reservationDraft: draft,
      availability: availability,
    );
  }

  // =========================================================
  // DECODIFICADOR
  // =========================================================

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        throw ApiException(
          response.statusCode,
          'El servidor devolvió una respuesta inválida.',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final fields = <String, String>{};

      final errors = body['errors'];

      if (errors is List) {
        for (final error in errors) {
          if (error is Map &&
              error['path'] != null &&
              error['message'] != null) {
            fields[error['path'].toString()] = error['message'].toString();
          }
        }
      } else if (errors is Map) {
        errors.forEach((key, value) {
          fields[key] = value.toString();
        });
      }

      throw ApiException(
        response.statusCode,
        body['message']?.toString() ?? 'No se pudo completar la operación.',
        fieldErrors: fields,
      );
    }

    return body;
  }
}
