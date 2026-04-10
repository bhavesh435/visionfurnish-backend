import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colours ─────────────────────────────────────────
  static const Color gold          = Color(0xFFD4A843);
  static const Color goldLight     = Color(0xFFE8C76A);
  static const Color goldDark      = Color(0xFFB8922F);
  static const Color bgDark        = Color(0xFF0F0F1A);
  static const Color surfaceDark   = Color(0xFF1A1A2E);
  static const Color cardDark      = Color(0xFF1E1E32);
  static const Color dividerColor  = Color(0xFF2A2A40);
  static const Color textPrimary   = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9EB8);
  static const Color success       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFFA726);
  static const Color danger        = Color(0xFFEF5350);
  static const Color info          = Color(0xFF42A5F5);

  // ── Theme Data ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: bgDark,
        secondary: goldLight,
        surface: surfaceDark,
        onSurface: textPrimary,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: gold),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceDark),
        dataRowColor: WidgetStateProperty.all(cardDark),
        headingTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: gold,
          fontSize: 13,
        ),
        dataTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
