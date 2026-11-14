import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String _font = 'PlusJakartaSans';

  static const TextStyle displayCurrency = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.64,
    color: AppColors.primaryContainer,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: -0.24,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AppColors.onSurface,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );
}
