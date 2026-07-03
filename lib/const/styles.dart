import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';
  static const String numbersFontFamily = 'DMMono';

  // ==========================================================================
  // Heading
  // ==========================================================================

  static const TextStyle display = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w800,
    fontSize: 36,
    height: 37 / 36,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 32 / 28,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 27 / 22,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 23 / 18,
  );

  // ==========================================================================
  // Body
  // ==========================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 18,
    height: 26 / 18,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
  );

  static const TextStyle bodyMediumSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle bodySmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
  );

  // ==========================================================================
  // Caption
  // ==========================================================================

  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 16 / 12,
  );

  // ==========================================================================
  // Button
  // ==========================================================================

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 16 / 14,
  );

  // ==========================================================================
  // Numbers (DM Mono)
  // ==========================================================================

  static const TextStyle numberLarge = TextStyle(
    fontFamily: numbersFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 22 / 18,
    letterSpacing: 0,
  );

  static const TextStyle numberMedium = TextStyle(
    fontFamily: numbersFontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static const TextStyle numberSmall = TextStyle(
    fontFamily: numbersFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 7,
    height: 10 / 7,
    letterSpacing: 0,
  );

  static const TextStyle numberXXL = TextStyle(
    fontFamily: numbersFontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 40,
    height: 60 / 40,
    letterSpacing: 0,
  );
}
