import 'package:flutter/material.dart';

/// RentMate App Colors - Teal Glassmorphism Theme
class AppColors {
  AppColors._();

  // Primary Teal Gradient
  static const Color primaryTeal = Color(0xFF06B6D4);
  static const Color primaryTealDark = Color(0xFF0891B2);
  static const Color primaryTealLight = Color(0xFF22D3EE);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, primaryTealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFE0F7FA), Color(0xFFFAFAFA), Color(0xFFFFF8E1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x20FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Background colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xB3FFFFFF); // 70% white for glass

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Glass effect colors
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassShadow = Color(0x15000000);

  // Accent colors
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentOrange = Color(0xFFFB923C);

  // Card styling (inspired by reference design)
  static const Color cardBorder = Color(0x20000000); // Subtle dark border
  static const Color cardBorderLight = Color(0x15000000);
  static const Color actionButtonBg = Color(0xFF1A1A2E); // Dark action button
  static const Color overlayDark = Color(0xCC000000); // For price overlays
}
