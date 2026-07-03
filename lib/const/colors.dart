import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ==========================================================================
  // Primary
  // ==========================================================================

  static const Color orange50 = Color(0xFFFFF7EF);
  static const Color orange100 = Color(0xFFFFFAF5);
  static const Color orange400 = Color(0xFFFF9A3C);
  static const Color orange500 = Color(0xFFFF6900);
  static const Color orange600 = Color(0xFFE06400);

  // ==========================================================================
  // Neutral
  // ==========================================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0D0D0D);

  static const Color gray10 = Color(0x1AFFFFFF);
  static const Color gray50 = Color(0x0D000000);
  static const Color gray100 = Color(0xFFF6F5F2);
  static const Color gray200 = Color(0xFFEDECE9);
  static const Color gray300 = Color(0xFFD0CFCC);
  static const Color gray400 = Color(0xFFC0BFBC);
  static const Color gray500 = Color(0xFF8A8880);
  static const Color gray800 = Color(0xFF2C2C2E);

  // ==========================================================================
  // Surface
  // ==========================================================================

  static const Color base = Color(0xFFF6F5F2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color sheet = Color(0xF7FFFFFF);

  static const Color overlay = Color(0x80000000);
  static const Color row = Color(0x05000000);

  // ==========================================================================
  // Semantic
  // ==========================================================================

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color errorBackground = Color(0xFFFEF2F2);

  // ==========================================================================
  // Accent
  // ==========================================================================

  static const Color blue = Color(0xFF635BFF);
  static const Color red = Color(0xFFF24E1E);
  static const Color teal = Color(0xFF32ADE6);
}
