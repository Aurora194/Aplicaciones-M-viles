import 'package:flutter/material.dart';

import '../state/auth_controller.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController auth,
    required super.child,
  }) : super(notifier: auth);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();

    if (scope == null || scope.notifier == null) {
      throw FlutterError('AuthScope no fue encontrado en el árbol de widgets.');
    }

    return scope.notifier!;
  }
}
