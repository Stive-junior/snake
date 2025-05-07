import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';

class AppTypography {
  static const String fontFamily = 'Tagesschrift';

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textColorPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textColorPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textColorPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    color: ColorPalette.textColorSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: ColorPalette.textColorSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: ColorPalette.textColorSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ColorPalette.textColorPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontStyle: FontStyle.italic,
    fontFamily: fontFamily,
  );
}
