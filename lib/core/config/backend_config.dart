/// سوئیچ بک‌اند: موک (دمو) ⇄ Firebase واقعی
///
/// • useMock = true  → داده‌های نمونه‌ی داخل حافظه (دمو فوری، بدون سرور)
/// • useMock = false → Firebase (Auth + Firestore + Functions)
///
/// برای اتصال به پروژه‌ی Firebase خود:
/// ۱) `flutterfire configure` را اجرا کنید تا lib/firebase_options.dart بازنویسی شود.
/// ۲) مقدار useMock را false کنید.
/// ۳) فایل‌های firebase/ (rules + functions + schema) را دیپلوی کنید.
class BackendConfig {
  static const bool useMock = true;
}
