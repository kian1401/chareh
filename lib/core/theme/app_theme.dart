import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// پالت گرم و صمیمی «چاره» — الهام از اپ‌های موفق خدمات منزل (کرم + نارنجی آتشین + هایلایت عسلی)
class AppColors {
  static const primary = Color(0xFFE85C24); // نارنجی گرم برند
  static const primaryDark = Color(0xFFC2451A);
  static const accent = Color(0xFFF5A524); // عسلی آفتابی
  static const bg = Color(0xFFFFF8F2); // کرم گرمایشی
  static const surface = Colors.white;
  static const text = Color(0xFF2A2019); // قهوه‌ای سوخته
  static const subtext = Color(0xFF7C6F63);
  static const success = Color(0xFF0E9F6E);
  static const danger = Color(0xFFE02424);
  static const info = Color(0xFF2D7DD2);
  static const warning = Color(0xFFD97706);
  static const border = Color(0xFFF1E3D5); // کرمی ملایم

  static const gradients = <List<Color>>[
    [Color(0xFFFF9A62), Color(0xFFE85C24)], // غروب
    [Color(0xFFF5A524), Color(0xFFC2451A)], // عسل به آتش
    [Color(0xFFFB8B7D), Color(0xFFCF4B64)], // کورال
    [Color(0xFFFBC54D), Color(0xFFB7791F)], // کهربا
    [Color(0xFF7FD3C1), Color(0xFF0E8474)], // فیروزهٔ گرم
    [Color(0xFFFF7E5F), Color(0xFFB83A2E)], // پیره‌ای
    [Color(0xFFD9A05B), Color(0xFF8C5A2B)], // مسی
    [Color(0xFF6D86F0), Color(0xFF4338CA)], // تک‌رنگ سرد برای تنوع
  ];

  static List<Color> gradientFor(String seed) =>
      gradients[seed.codeUnits.fold<int>(0, (a, b) => a + b) % gradients.length];
}

class AppTheme {
  static ThemeData get light {
    final textTheme = GoogleFonts.vazirmatnTextTheme();
    const radius = 16.0;

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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: GoogleFonts.getFont('Vazirmatn',
              fontSize: 15, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.getFont('Vazirmatn',
              fontSize: 13.5, fontWeight: FontWeight.w800),
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
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.getFont('Vazirmatn',
              fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
