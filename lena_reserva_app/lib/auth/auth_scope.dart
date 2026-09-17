import 'package:flutter/material.dart';

import '../state/auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController auth,
    required Widget child,
  }) : super(notifier: auth, child: child);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();

    if (scope == null || scope.notifier == null) {
      throw FlutterError('AuthScope no fue encontrado en el árbol de widgets.');
    }

    return scope.notifier!;
  }
}
