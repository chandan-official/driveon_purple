import 'package:flutter/material.dart';

class AppColors {
  // --- New Premium Brand Colors ---
  static const Color primaryPurple = Color(0xFF6F42C1); // Main Buttons, Headers
  static const Color primaryGold = Color(0xFFD4AF37); // Icons, Stars, Logo
  static const Color secondaryTeal = Color(0xFF20C997); // Success, Verified

  // --- Backgrounds & Neutrals ---
  static const Color backgroundLight = Color(0xFFFFFFFF); // White
  static const Color backgroundDark = Color(0xFFF8F9FA); // Light Grey
  static const Color textDark = Color(0xFF212529); // Charcoal
  static const Color textGrey = Color(0xFF6C757D); // Subtitles

  // --- Functional Colors ---
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF20C997);
  static const Color warning = Color(0xFFFFC107);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6F42C1), Color(0xFF5A32A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
