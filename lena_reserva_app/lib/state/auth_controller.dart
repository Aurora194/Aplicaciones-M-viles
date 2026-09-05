import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthController extends ChangeNotifier {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'user_email';

  String? accessToken;
  String? refreshToken;
  String? userEmail;
  String? restoreError;
  bool isReady = false;

  bool get isAuthenticated {
    final token = accessToken;
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiration = (payload['exp'] as num?)?.toInt();
      return expiration == null || expiration > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return false;
    }
  }

  int? get userId {
    if (!isAuthenticated) return null;
    try {
      final payload = accessToken!.split('.')[1];
      final decoded = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload))));
      return (decoded['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> restore() async {
    restoreError = null;
    try {
      final preferences = await SharedPreferences.getInstance();
      accessToken = preferences.getString(_accessTokenKey);
      refreshToken = preferences.getString(_refreshTokenKey);
      userEmail = preferences.getString(_emailKey);
    } catch (error) {
      restoreError = 'No se pudo recuperar la sesión guardada.';
    } finally {
      isReady = true;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String token,
    String? newRefreshToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, token);
    if (newRefreshToken != null) {
      await preferences.setString(_refreshTokenKey, newRefreshToken);
    }
    await preferences.setString(_emailKey, email);
    accessToken = token;
    refreshToken = newRefreshToken;
    userEmail = email;
    notifyListeners();
  }

  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_emailKey);
    accessToken = null;
    refreshToken = null;
    userEmail = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope no está disponible en este contexto.');
    return scope!.notifier!;
  }
}
