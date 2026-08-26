import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // TOKENS PRIMITIVOS
  static const Color brandPrimary = Color(0xFF8B0000);
  static const Color brandSecondary = Color(0xFFD4A017);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutral50 = Color(0xFFF8F8F8);
  static const Color neutral100 = Color(0xFFF1F1F1);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral600 = Color(0xFF666666);
  static const Color neutral900 = Color(0xFF222222);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // TOKENS SEMÁNTICOS

  static const Color background = neutral50;
  static const Color surface = neutralWhite;
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color border = neutral200;
  static const Color primary = brandPrimary;
  static const Color secondary = brandSecondary;
  static const Color primaryLight = Color(0xFFB22222);
  static const Color danger = error;
  static const Color onPrimary = neutralWhite;
  static const Color onSecondary = neutralBlack;
  static const Color successText = success;
  static const Color errorText = error;
  static const Color warningText = warning;
  static const Color infoText = info;
}
