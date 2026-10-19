import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// پالت برند «چاره»
class AppColors {
  static const primary = Color(0xFF6D28D9); // بنفش اصلی
  static const primaryDark = Color(0xFF5B21B6);
  static const accent = Color(0xFFF59E0B); // کهربایی
  static const bg = Color(0xFFF7F7FA);
  static const surface = Colors.white;
  static const text = Color(0xFF1F2937);
  static const subtext = Color(0xFF6B7280);
  static const success = Color(0xFF059669);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
  static const warning = Color(0xFFD97706);
  static const border = Color(0xFFE9E9EF);

  static const gradients = <List<Color>>[
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFF0EA5E9), Color(0xFF0369A1)],
    [Color(0xFFF59E0B), Color(0xFFB45309)],
    [Color(0xFF10B981), Color(0xFF047857)],
    [Color(0xFFEC4899), Color(0xFFB21B68)],
    [Color(0xFFF97316), Color(0xFFC2410C)],
    [Color(0xFF14B8A6), Color(0xFF0F766E)],
    [Color(0xFF6366F1), Color(0xFF4338CA)],
  ];

  static List<Color> gradientFor(String seed) =>
      gradients[seed.codeUnits.fold<int>(0, (a, b) => a + b) % gradients.length];
}

class AppTheme {
  static ThemeData get light {
    final textTheme = GoogleFonts.vazirmatnTextTheme();
    const radius = 14.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        titleTextStyle: GoogleFonts.getFont('Vazirmatn',
            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.getFont('Vazirmatn',
              fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: .12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.getFont('Vazirmatn',
              fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
