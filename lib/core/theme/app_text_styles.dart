import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindclash/core/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Primary Display & Hero
  static TextStyle hero({Color color = AppColors.textPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle body({Color color = AppColors.textSecondary}) =>
      GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.3,
      );

  static TextStyle button({Color color = Colors.white, double fontSize = 16}) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      );

  // Monospaced Numbers, Codes & Timers
  static TextStyle digitalCode({Color color = AppColors.solarCore, double fontSize = 28}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 2.0,
      );

  static TextStyle timerNumber({Color color = Colors.white, double fontSize = 18}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
