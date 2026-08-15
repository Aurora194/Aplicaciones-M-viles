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
}
