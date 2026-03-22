import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF4500);
  static const Color primaryDark = Color(0xFFCC3700);
  static const Color secondary = Color(0xFFFF7A00);
  static const Color accent = Color(0xFFFFB347);

  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color backgroundCard = Color(0xFF1A1A1A);
  static const Color backgroundLight = Color(0xFFF9F9F9);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDark = Color(0xFF111111);
  static const Color textMuted = Color(0xFF6B6B6B);

  static const Color surface = Color(0xFF1E1E1E);
  static const Color divider = Color(0xFF2A2A2A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF7A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF1C0A00), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF2A1500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
