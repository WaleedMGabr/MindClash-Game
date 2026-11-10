import 'package:flutter/material.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';

class AppDecorations {
  AppDecorations._();

  // Glassmorphic Card Container
  static BoxDecoration glassCard({
    Color color = AppColors.obsidianGlass,
    Color borderColor = AppColors.borderSubtle,
    double borderRadius = 18.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Glowing Neon Card Container
  static BoxDecoration neonCard({
    required Color glowColor,
    Color backgroundColor = AppColors.obsidianGlass,
    double borderRadius = 18.0,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor.withOpacity(0.6), width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.2),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Input Field Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: AppTextStyles.bodySmall(color: AppColors.textMuted),
      labelStyle: AppTextStyles.bodySmall(color: AppColors.neonLavender),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.electricViolet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyberCrimson),
      ),
    );
  }

  // Gradient Primary Action Button Style
  static ButtonStyle primaryButtonStyle({
    double borderRadius = 14.0,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.deepPurpleAccent,
      foregroundColor: Colors.white,
      padding: padding,
      elevation: 6,
      shadowColor: AppColors.electricViolet.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
