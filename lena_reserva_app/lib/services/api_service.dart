import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/api/health'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Error del servidor: ${response.statusCode}');
  }

  /// Intenta iniciar sesión contra el endpoint /api/login.
  /// Devuelve true si el servidor responde 200. Lanza excepción en caso contrario.
  /// Hace login contra /api/auth/login. Envía { correo, password }.
  /// Devuelve un mapa con los tokens si tiene éxito: { accessToken, refreshToken }.
  /// Lanza excepción con mensaje legible en caso de fallo.
  static Future<Map<String, dynamic>> login(String correo, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    // Intentar parsear JSON del cuerpo (si existe)
    Map<String, dynamic>? bodyJson;
    try {
      if (response.body.isNotEmpty) bodyJson = jsonDecode(response.body);
    } catch (_) {
      // ignore JSON parse errors for now
    }

    if (response.statusCode == 200) {
      // Devolver tokens (o el cuerpo completo) para que el cliente los use
      return bodyJson ?? {'success': true};
    }

    // Obtener mensaje de error desde el JSON o el body crudo
    String message;
    if (bodyJson != null && bodyJson['message'] != null) {
      message = bodyJson['message'].toString();
    } else if (response.body.isNotEmpty) {
      message = response.body;
    } else {
      message = 'Status ${response.statusCode}';
    }

    throw Exception('Login fallido: $message');
  }
}
