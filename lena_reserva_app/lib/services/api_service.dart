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
  // CLIENTE HTTP INYECTABLE PARA PRUEBAS
  // =========================================================

  static http.Client _client = http.Client();

  static http.Client get client => _client;

  static set client(http.Client value) {
    _client = value;
  }

  static void resetClient() {
    _client = http.Client();
  }

  // =========================================================
  // DIRECCIONES DEL BACKEND
  // =========================================================

  static const String emulatorBaseUrl = 'http://10.0.2.2:3000';

  static const String physicalDeviceBaseUrl = 'http://192.168.1.3:3000';

  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return physicalDeviceBaseUrl;
    }

    if (Platform.isAndroid) {
      return emulatorBaseUrl;
    }

    return physicalDeviceBaseUrl;
  }

  // =========================================================
  // HEADERS
  // =========================================================

  static Map<String, String> _authorizationHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  static Map<String, String> _jsonAuthorizationHeaders(String token) {
    return {
      ..._authorizationHeaders(token),
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Map<String, String> _jsonHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  // =========================================================
  // RENOVACIÓN DEL ACCESS TOKEN
  // =========================================================

  /// Solicita un nuevo accessToken utilizando el refreshToken.
  ///
  /// Endpoint del backend:
  /// POST /api/auth/refresh
  ///
  /// Respuesta esperada:
  /// {
  ///   "success": true,
  ///   "accessToken": "..."
  /// }
  static Future<String> refreshAccessToken(String refreshToken) async {
    final cleanRefreshToken = refreshToken.trim();

    if (cleanRefreshToken.isEmpty) {
      throw const ApiException(401, 'Refresh Token requerido.');
    }

    final url = '$baseUrl/api/auth/refresh';

    debugPrint('========================================');
    debugPrint('RENOVACIÓN DE ACCESS TOKEN');
    debugPrint('URL: $url');
    debugPrint('Refresh Token enviado: true');
    debugPrint('========================================');

    final response = await _client
        .post(
          Uri.parse(url),
          headers: _jsonHeaders(),
          body: jsonEncode({'refreshToken': cleanRefreshToken}),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint('REFRESH STATUS: ${response.statusCode}');

    final body = _decode(response);

    final accessToken = body['accessToken']?.toString().trim();

    if (accessToken == null || accessToken.isEmpty || accessToken == 'null') {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió un nuevo token de acceso.',
      );
    }

    debugPrint('Nuevo Access Token recibido: true');

    return accessToken;
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

    final response = await _client
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

    final response = await _client
        .post(
          Uri.parse(url),
          headers: _jsonHeaders(),
          body: jsonEncode({'correo': correo, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: ${response.body}');

    return _decode(response);
  }

  static Future<Map<String, dynamic>> forgotPassword(String correo) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/forgot-password'),
          headers: _jsonHeaders(),
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

    return _decode(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/reset-password'),
          headers: _jsonHeaders(),
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
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: _jsonHeaders(),
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

  static Future<List<Reservation>> getReservations(
    String token, {
    String? cliente,
    int? mesa,
    DateTime? fecha,
    String? estado,
    String order = 'asc',
    int page = 1,
    int limit = 100,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'order': order,
    };

    if (cliente != null && cliente.trim().isNotEmpty) {
      queryParameters['cliente'] = cliente.trim();
    }

    if (mesa != null) {
      queryParameters['mesa'] = mesa.toString();
    }

    if (fecha != null) {
      queryParameters['fecha'] = fecha.toUtc().toIso8601String();
    }

    if (estado != null &&
        estado.trim().isNotEmpty &&
        estado.toUpperCase() != 'TODAS') {
      queryParameters['estado'] = estado.toUpperCase();
    }

    final uri = Uri.parse(
      '$baseUrl/api/reservas',
    ).replace(queryParameters: queryParameters);

    final response = await _client
        .get(uri, headers: _authorizationHeaders(token))
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final rawData = body['data'];

    if (rawData is! List) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió una lista de reservas.',
      );
    }

    return rawData
        .whereType<Map>()
        .map((item) => Reservation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // =========================================================
  // OBTENER UNA RESERVA
  // =========================================================

  static Future<Reservation> getReservation(String token, int id) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final rawData = body['data'];

    if (rawData is! Map) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió los datos de la reserva.',
      );
    }

    return Reservation.fromJson(Map<String, dynamic>.from(rawData));
  }

  // =========================================================
  // CREAR RESERVA
  // =========================================================

  static Future<Reservation> createReservation({
    required String token,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,

    /// Refresh token opcional.
    ///
    /// Si el servidor responde 401 y se proporciona este token,
    /// se intenta renovar automáticamente el accessToken.
    String? refreshToken,

    /// Callback opcional para guardar el nuevo accessToken.
    ///
    /// En producción se puede conectar con:
    ///
    /// auth.updateAccessToken
    Future<void> Function(String newAccessToken)? onTokenRefreshed,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reservas');

    final requestBody = jsonEncode({
      'fecha': date.toUtc().toIso8601String(),
      'personas': people,
      'usuarioId': userId,
      'mesaId': tableId,
    });

    // ========================================================
    // PRIMER INTENTO
    // ========================================================

    debugPrint('========================================');
    debugPrint('CREAR RESERVA');
    debugPrint('URL: $uri');
    debugPrint('Primer intento');
    debugPrint('========================================');

    var response = await _client
        .post(uri, headers: _jsonAuthorizationHeaders(token), body: requestBody)
        .timeout(const Duration(seconds: 10));

    // ========================================================
    // HTTP 401
    // ========================================================

    if (response.statusCode == 401) {
      debugPrint('========================================');
      debugPrint('HTTP 401 DETECTADO');
      debugPrint('Access Token inválido o expirado.');
      debugPrint('========================================');

      // ------------------------------------------------------
      // No existe refresh token
      // ------------------------------------------------------

      if (refreshToken == null || refreshToken.trim().isEmpty) {
        return _decode(response).let<Reservation>(
          (_) => throw const ApiException(401, 'Token inválido o expirado.'),
        );
      }

      // ------------------------------------------------------
      // Intentar renovar token
      // ------------------------------------------------------

      final newAccessToken = await refreshAccessToken(refreshToken);

      // ------------------------------------------------------
      // Guardar nuevo token si existe callback
      // ------------------------------------------------------

      if (onTokenRefreshed != null) {
        await onTokenRefreshed(newAccessToken);
      }

      debugPrint('========================================');
      debugPrint('TOKEN RENOVADO');
      debugPrint('Reintentando crear la reserva...');
      debugPrint('========================================');

      // ------------------------------------------------------
      // SEGUNDO INTENTO
      // ------------------------------------------------------

      response = await _client
          .post(
            uri,
            headers: _jsonAuthorizationHeaders(newAccessToken),
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'REINTENTO RESERVA STATUS: '
        '${response.statusCode}',
      );
    }

    // ========================================================
    // DECODIFICAR RESPUESTA
    // ========================================================

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

  // =========================================================
  // ACTUALIZAR RESERVA
  // =========================================================

  static Future<Reservation> updateReservation({
    required String token,
    required int id,
    required DateTime date,
    required int people,
    required int userId,
    required int tableId,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: _jsonAuthorizationHeaders(token),
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
        'El servidor no devolvió los datos de la reserva actualizada.',
      );
    }

    return Reservation.fromJson(Map<String, dynamic>.from(rawData));
  }

  // =========================================================
  // CAMBIAR ESTADO DE RESERVA
  // =========================================================

  static Future<Reservation> updateReservationStatus({
    required String token,
    required int id,
    required String status,
  }) async {
    final normalizedStatus = status.trim().toUpperCase();

    const validStatuses = {'PENDIENTE', 'CONFIRMADA', 'CANCELADA'};

    if (!validStatuses.contains(normalizedStatus)) {
      throw const ApiException(422, 'Estado de reserva inválido.');
    }

    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: _jsonAuthorizationHeaders(token),
          body: jsonEncode({'estado': normalizedStatus}),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final rawData = body['data'];

    if (rawData is! Map) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió los datos de la reserva actualizada.',
      );
    }

    return Reservation.fromJson(Map<String, dynamic>.from(rawData));
  }

  // =========================================================
  // ELIMINAR RESERVA
  // =========================================================

  static Future<void> deleteReservation({
    required String token,
    required int id,
  }) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/api/reservas/$id'),
          headers: _authorizationHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    _decode(response);
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

    final response = await _client
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
    final response = await _client
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

  // =========================================================
  // CREAR MESA
  // =========================================================

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

    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/mesas'),
          headers: _jsonAuthorizationHeaders(token),
          body: jsonEncode({
            'numero': nombreMesa,
            'capacidad': capacidad,
            'disponible': disponible,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final mesa = body['mesa'];

    if (mesa is! Map) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió los datos de la mesa creada.',
      );
    }

    return Map<String, dynamic>.from(mesa);
  }

  // =========================================================
  // ACTUALIZAR MESA
  // =========================================================

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

    final response = await _client
        .put(
          Uri.parse('$baseUrl/api/mesas/$id'),
          headers: _jsonAuthorizationHeaders(token),
          body: jsonEncode({
            'numero': nombreMesa,
            'capacidad': capacidad,
            'disponible': disponible,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = _decode(response);

    final mesa = body['mesa'];

    if (mesa is! Map) {
      throw ApiException(
        response.statusCode,
        'El servidor no devolvió los datos de la mesa actualizada.',
      );
    }

    return Map<String, dynamic>.from(mesa);
  }

  // =========================================================
  // ELIMINAR MESA
  // =========================================================

  static Future<void> deleteTable({
    required String token,
    required int id,
  }) async {
    final response = await _client
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
    final response = await _client
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
    final response = await _client
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

// =========================================================
// EXTENSIÓN AUXILIAR
// =========================================================

extension _LetExtension<T> on T {
  R let<R>(R Function(T value) function) {
    return function(this);
  }
}
