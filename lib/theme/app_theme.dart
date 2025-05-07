import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: ColorPalette.primaryColor,
    hintColor: ColorPalette.secondaryColor,
    scaffoldBackgroundColor: ColorPalette.backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: ColorPalette.primaryColor,
      secondary: ColorPalette.secondaryColor,
      tertiary: ColorPalette.accentColor,
      surface: ColorPalette.surfaceColor,
      error: ColorPalette.errorColor,
      onPrimary: ColorPalette.backgroundColor,
      onSecondary: ColorPalette.backgroundColor,
      onSurface: ColorPalette.textColorPrimary,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorPalette.surfaceColor,
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: ColorPalette.textColorPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.primaryColor,
        foregroundColor: ColorPalette.backgroundColor,
        textStyle: AppTypography.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.primaryColor,
        textStyle: AppTypography.button.copyWith(
          color: ColorPalette.primaryColor,
        ),
        side: BorderSide(color: ColorPalette.primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
  );
}
