/// اینترفیس‌های بک‌اند — پیاده‌سازی موک و Firebase هر دو همین قرارداد را اجرا می‌کنند.
library;

import 'models.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchUser();

  /// کد تولیدشده برگشت داده می‌شود تا در حالت تست روی صفحه نمایش داده شود (بدون SMS)
  Future<String> sendOtp({required String phone, required UserRole role});
  Future<AppUser> verifyOtp({
    required String phone,
    required String code,
    String? referralCode,
  });

  /// ورود سریع دمو (فقط حالت موک — قابلیت سینمایی برای استم که رابط ندارد)
  Future<AppUser> signInDemo(UserRole role);

  Future<void> toggleFavorite(String serviceId);
  Future<void> signOut();
}

abstract class CatalogRepository {
  Stream<List<Category>> watchCategories({bool includeHidden = false});
  Stream<List<ServiceItem>> watchServices({
    String? categoryId,
    String? query,
    bool includeHidden = false,
  });
  Stream<ServiceItem?> watchService(String id);
  Stream<List<Review>> watchReviews(String serviceId);
  Stream<List<ProviderProfile>> watchProviders({bool activeOnly = true});
  Stream<List<City>> watchCities({bool activeOnly = true});

  // مدیریت (ادمین)
  Future<void> upsertService(ServiceItem s);
  Future<void> deleteService(String id);
  Future<void> upsertCategory(Category c);
  Future<void> deleteCategory(String id);
  Future<void> upsertCity(City c);
  Future<void> deleteCity(String id);
}

abstract class BookingRepository {
  Stream<List<Booking>> watchCustomerBookings(String customerId);
  Stream<List<Booking>> watchProviderRequests(
    String cityId,
  ); // سفارش‌های باز بازار (در انتظار پذیرش)
  Stream<List<Booking>> watchProviderJobs(String providerId);
  Stream<List<Booking>> watchAll(); // ادمین
  Stream<Booking?> watchBookingById(String id);

  Future<Booking> createBooking({
    required BookingDraft draft,
    required AppUser customer,
  });
  Future<void> accept(
    String bookingId,
    ProviderProfile provider, {
    required String day,
    required String slot,
  });
  Future<void> reject(String bookingId, {String? reason});
  Future<void> advance(String bookingId); // گام بعدی وضعیت
  Future<void> updateStatus(
    String bookingId,
    BookingStatus status, {
    String? note,
  });
  Future<void> cancel(String bookingId);
  Future<void> rate(
    String bookingId, {
    required int stars,
    required String text,
    required String author,
  });
}

abstract class ProviderRepository {
  Stream<ProviderProfile?> watchProfile(String providerId);
  Stream<List<ProviderProfile>> watchAll();
  Stream<List<EarningEntry>> watchEarnings(String providerId);
  Future<void> setOnline(String providerId, bool online);
  Future<void> setVerified(String providerId, bool verified);
  Future<void> upsertProvider(ProviderProfile p);
  Future<void> removeProvider(String providerId);
}

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchThread(String threadId);
  Future<void> send(String threadId, String text, {bool fromCustomer = true});
}

abstract class MiscRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAllRead(String userId);
  Future<List<AddressItem>> getAddresses(String userId);
  Future<void> addAddress(
    String userId, {
    required String title,
    required String text,
    double lat = 37.55,
    double lng = 45.07,
    String cityId = 'urmia',
    String plaque = '',
    String floor = '',
    String unit = '',
  });
  Stream<double> watchCommission(); // درصد کمیسیون پلتفرم
  Future<void> setCommission(double v);

  // ⚙️ تنظیمات CMS (تم، شهر پیش‌فرض، کلید AI، شبکه‌ها...)
  Stream<AppSettings> watchSettings();
  Future<void> saveSettings(AppSettings s);

  // 💰 کیف پول واقعی‌نما: شارژ + بونس پلکانی + تراکنش‌ها
  Stream<List<WalletTxn>> watchWallet(String userId);
  Future<({int bonus, int total})> chargeWallet(String userId, int amount);
  Future<bool> payWithWallet(String userId, int amount, String label);

  /// دستیار هوشمند (Gemini روی Cloud Functions — در حالت موک: پاسخ قاعده‌محور)
  Future<String> askAssistant(String prompt);

  /// 🤖 کارشناس عیب‌یابی متخصص (پرووایدر) — اگر کلید Gemini در تنظیمات باشد آنلاین، وگرنه آفلاین قاعده‌محور
  Future<String> askProviderExpert(String prompt);

  // 🔐 مدیران سیستم — فقط شمارهٔ ارشد (۰۹۱۴۸۰۰۲۴۶۱) می‌تواند مدیر جدید ثبت کند
  Stream<List<String>> watchAdminPhones();
  Future<void> addAdminPhone(String phone);
  Future<void> removeAdminPhone(String phone);
}
