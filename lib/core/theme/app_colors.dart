import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background Surfaces
  static const Color voidCanvas = Color(0xFF09080E);
  static const Color obsidianGlass = Color(0xFF12101F);
  static const Color elevatedSlate = Color(0xFF1B1830);
  static const Color cardSurface = Color(0xFF1E1D36);
  static const Color inputSurface = Color(0xFF151325);

  // Border & Strokes
  static const Color borderSubtle = Color(0x1FFFFFFF); // 12% white
  static const Color borderFrost = Color(0x28FFFFFF);  // 16% white
  static const Color borderActive = Color(0x998B5CF6); // 60% electric violet

  // Primary Accent (Traps & Brand)
  static const Color electricViolet = Color(0xFF8B5CF6);
  static const Color neonLavender = Color(0xFFC084FC);
  static const Color deepPurpleAccent = Color(0xFF7C3AED);

  // Success & Knowledge (Correct Answers & Ready)
  static const Color hyperEmerald = Color(0xFF10B981);
  static const Color mintCyan = Color(0xFF34D399);

  // Energy & Timer (Gold & Warnings)
  static const Color voltAmber = Color(0xFFF59E0B);
  static const Color solarCore = Color(0xFFFBBF24);

  // Danger & Timeout (Alarms & Forfeit)
  static const Color cyberCrimson = Color(0xFFEF4444);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient trapGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient truthGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
