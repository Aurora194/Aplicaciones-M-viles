import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_logger.dart';

class AuthController extends ChangeNotifier {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEmail = 'user_email';
  static const String _keyRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyName = 'user_name';
  static const String _keyLastName = 'user_last_name';

  String? _accessToken;
  String? _refreshToken;

  String? _email;
  String? _role;
  int? _userId;
  String? _name;
  String? _lastName;

  bool _isReady = false;
  String? _restoreError;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  String? get userEmail => _email;

  String? get userRole => _role;

  int? get userId => _userId;

  String? get userName => _name;

  String? get userLastName => _lastName;

  bool get isReady => _isReady;

  String? get restoreError => _restoreError;

  // ============================================================
  // AUTENTICACIÓN
  // ============================================================

  bool get isAuthenticated {
    final token = _accessToken;

    if (token == null || token.trim().isEmpty) {
      return false;
    }

    return true;
  }

  // ============================================================
  // RUTA INICIAL
  // ============================================================

  String get landingRoute {
    if (userRole == 'ADMIN') {
      return '/app/reservas';
    }

    return '/cliente';
  }

  // ============================================================
  // INICIAR SESIÓN
  // ============================================================

  Future<void> signIn({
    required String email,
    required String token,
    String? newRefreshToken,
    String? role,
    int? id,
    String? name,
    String? lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanToken = token.trim();

    _accessToken = cleanToken;
    _refreshToken = newRefreshToken?.trim();

    _email = email.trim();

    _role = role?.trim().toUpperCase();
    _userId = id;
    _name = name?.trim();
    _lastName = lastName?.trim();

    // ------------------------------------------------------------
    // GUARDAR DATOS
    // ------------------------------------------------------------

    await prefs.setString(_keyAccessToken, cleanToken);

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    } else {
      await prefs.remove(_keyRefreshToken);
    }

    await prefs.setString(_keyEmail, _email!);

    if (_role != null && _role!.isNotEmpty) {
      await prefs.setString(_keyRole, _role!);
    } else {
      await prefs.remove(_keyRole);
    }

    if (_userId != null) {
      await prefs.setInt(_keyUserId, _userId!);
    } else {
      await prefs.remove(_keyUserId);
    }

    if (_name != null && _name!.isNotEmpty) {
      await prefs.setString(_keyName, _name!);
    } else {
      await prefs.remove(_keyName);
    }

    if (_lastName != null && _lastName!.isNotEmpty) {
      await prefs.setString(_keyLastName, _lastName!);
    } else {
      await prefs.remove(_keyLastName);
    }

    _restoreError = null;
    _isReady = true;

    notifyListeners();

    // ------------------------------------------------------------
    // LOG SEGURO
    // ------------------------------------------------------------
    //
    // NO registrar:
    // - token
    // - refresh token
    // - correo
    // - ID
    // - nombre
    // - apellido
    //
    // Solo registramos indicadores booleanos y datos técnicos.
    //

    AppLogger.info('auth_session_saved', {
      'authenticated': isAuthenticated,
      'roleAvailable': _role != null && _role!.isNotEmpty,
      'userIdAvailable': _userId != null,
      'nameAvailable': _name != null && _name!.isNotEmpty,
      'lastNameAvailable': _lastName != null && _lastName!.isNotEmpty,
      'destination': landingRoute,
    });
  }

  // ============================================================
  // SESIÓN DE PRUEBA
  // ============================================================

  /// Configura una sesión únicamente para pruebas automatizadas.
  /// No utiliza SharedPreferences.
  void setTestSession({
    required String token,
    required int userId,
    String? refreshToken,
  }) {
    _accessToken = token.trim();
    _refreshToken = refreshToken?.trim();

    _email = 'test@example.com';
    _role = 'CLIENTE';
    _userId = userId;
    _name = 'Usuario';
    _lastName = 'Prueba';

    _isReady = true;
    _restoreError = null;

    notifyListeners();
  }

  // ============================================================
  // RESTAURAR SESIÓN
  // ============================================================

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString(_keyAccessToken);
      final savedRefreshToken = prefs.getString(_keyRefreshToken);
      final savedEmail = prefs.getString(_keyEmail);
      final savedRole = prefs.getString(_keyRole);
      final savedUserId = prefs.getInt(_keyUserId);
      final savedName = prefs.getString(_keyName);
      final savedLastName = prefs.getString(_keyLastName);

      _accessToken = savedToken?.trim();
      _refreshToken = savedRefreshToken?.trim();

      _email = savedEmail;
      _role = savedRole?.trim().toUpperCase();
      _userId = savedUserId;
      _name = savedName;
      _lastName = savedLastName;

      _restoreError = null;
    } catch (e) {
      _restoreError = e.toString();

      _accessToken = null;
      _refreshToken = null;
      _email = null;
      _role = null;
      _userId = null;
      _name = null;
      _lastName = null;
    }

    _isReady = true;

    notifyListeners();

    // ------------------------------------------------------------
    // LOG SEGURO DE RESTAURACIÓN
    // ------------------------------------------------------------
    //
    // No mostramos:
    // - correo
    // - ID
    // - nombre
    // - apellido
    // - token
    // - contenido del token
    //

    AppLogger.info('auth_session_restored', {
      'authenticated': isAuthenticated,
      'tokenAvailable': _accessToken != null && _accessToken!.isNotEmpty,
      'refreshTokenAvailable':
          _refreshToken != null && _refreshToken!.isNotEmpty,
      'roleAvailable': _role != null && _role!.isNotEmpty,
      'userIdAvailable': _userId != null,
      'destination': landingRoute,
      'restoreError': _restoreError != null,
    });
  }

  // ============================================================
  // ACTUALIZAR TOKEN
  // ============================================================

  Future<void> updateAccessToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      return;
    }

    _accessToken = cleanToken;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyAccessToken, cleanToken);

    notifyListeners();

    // Nunca registrar el token ni parte de su contenido.
    AppLogger.info('auth_access_token_updated');
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyLastName);

    _accessToken = null;
    _refreshToken = null;
    _email = null;
    _role = null;
    _userId = null;
    _name = null;
    _lastName = null;

    _isReady = true;
    _restoreError = null;

    notifyListeners();

    AppLogger.info('auth_session_closed', {'authenticated': isAuthenticated});
  }

  // ============================================================
  // DECODIFICAR JWT
  // ============================================================

  Map<String, dynamic>? decodeToken() {
    try {
      final token = _accessToken;

      if (token == null || token.trim().isEmpty) {
        return null;
      }

      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(base64Url.decode(normalized));

      final data = jsonDecode(decoded);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
