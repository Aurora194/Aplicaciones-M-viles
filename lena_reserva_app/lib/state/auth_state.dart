class AuthState {
  AuthState._();

  static String? _accessToken;

  static bool get isAuthenticated => _accessToken != null;

  static String? get accessToken => _accessToken;

  static void setToken(String token) {
    _accessToken = token;
  }

  static void clearSession() {
    _accessToken = null;
  }
}
