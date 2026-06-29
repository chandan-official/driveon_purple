import 'package:flutter/material.dart';

class AppColors {
  // --- Ryndo Mobility Brand Colors ---
  static const Color primaryPurple = Color(0xFF6C40C7); // Figma Purple
  static const Color primaryGold = Color(0xFFFFD700);   // Gold for logo
  static const Color secondaryTeal = Color(0xFF20C997); 

  // --- Backgrounds & Neutrals ---
  static const Color backgroundLight = Color(0xFFFFFFFF); // White
  static const Color backgroundDark = Color(0xFFF3F4F6);  // Rounded Field Grey
  static const Color textDark = Color(0xFF000000);        // Pure Black for headings
  static const Color textGrey = Color(0xFF8E8E93);        // iOS-style subtitle grey

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
