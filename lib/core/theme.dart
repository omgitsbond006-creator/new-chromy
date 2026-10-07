import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B0820);
  static const backgroundTop = Color(0xFF1A1145);
  static const panel = Color(0xFF17123A);
  static const cyan = Color(0xFF5CE1FF);
  static const magenta = Color(0xFFFF4D8D);
  static const gem = Color(0xFF7CFFB2);
  static const gold = Color(0xFFFFE066);
  static const violet = Color(0xFFB98CFF);
  static const orange = Color(0xFFFFB347);
  static const text = Color(0xFFF2EEFF);
  static const textDim = Color(0xFF9A93C9);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
      surface: AppColors.panel,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.panel),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.cyan
            : AppColors.textDim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.cyan.withValues(alpha: 0.35)
            : AppColors.panel,
      ),
    ),
  );
}

TextStyle titleStyle(double size, {Color color = AppColors.text}) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w900,
  letterSpacing: size * 0.12,
  color: color,
  shadows: [
    Shadow(color: AppColors.cyan.withValues(alpha: 0.8), blurRadius: 18),
    Shadow(color: AppColors.magenta.withValues(alpha: 0.5), blurRadius: 36),
  ],
);
