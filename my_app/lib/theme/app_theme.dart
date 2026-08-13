import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B4332);
  static const primaryLight = Color(0xFF2D6A4F);
  static const accent = Color(0xFF40916C);
  static const surface = Color(0xFFF8FAF9);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1D3557);
  static const textSecondary = Color(0xFF6B7280);
  static const warning = Color(0xFFF4A261);
  static const danger = Color(0xFFE63946);
  static const heroBall = Color(0xFFE76F51);
  static const teamBall = Color(0xFF2A9D8F);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
  );
}
