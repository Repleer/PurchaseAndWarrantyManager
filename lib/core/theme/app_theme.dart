import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Світла тема застосунку (прототип виконано у світлій темі).
abstract final class AppTheme {
  static ThemeData get light {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      // Якщо шрифт Inter не підключено, використовується системний шрифт macOS.
      fontFamily: 'Inter',
      fontFamilyFallback: const ['SF Pro Text', '.AppleSystemUIFont'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 480,
      ),
    );
  }
}
