import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';

/// 🎨 کنترلر تم لحظه‌ای — هر چیز ادمین (رنگ، فونت، برند) زنده روی اپ اعمال می‌شود
class ThemeState extends ChangeNotifier {
  ThemeState() {
    RepoHub.instance.misc.watchSettings().listen((s) {
      settings = s;
      notifyListeners();
    });
  }

  AppSettings settings = AppSettings();

  Color get seed {
    try {
      return Color(int.parse(settings.primaryHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6D28D9);
    }
  }

  String get appTitle => settings.appTitle;
  String get logoEmoji => settings.logoEmoji;
  String get heroImageUrl => settings.heroImageUrl;

  ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: settings.fontFamily,
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        titleTextStyle: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
              fontFamily: settings.fontFamily, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
