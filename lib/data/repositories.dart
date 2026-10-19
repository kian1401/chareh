/// اینترفیس‌های بک‌اند — پیاده‌سازی موک و Firebase هر دو همین قرارداد را اجرا می‌کنند.
library;

import 'models.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchUser();

  Future<void> sendOtp({required String phone, required UserRole role});
  Future<AppUser> verifyOtp({required String phone, required String code, String? referralCode});

  Future<void> toggleFavorite(String serviceId);
  Future<void> signOut();
}

abstract class CatalogRepository {
  Stream<List<Category>> watchCategories({bool includeHidden = false});
  Stream<List<ServiceItem>> watchServices({String? categoryId, String? query, bool includeHidden = false});
  Stream<ServiceItem?> watchService(String id);
  Stream<List<Review>> watchReviews(String serviceId);
  Stream<List<ProviderProfile>> watchProviders({bool activeOnly = true});
  Stream<List<City>> watchCities({bool activeOnly = true});

  // 🛠️ مدیریت کامل ادمین: دسته‌ها + زیرمجموعه‌ها + شهرها
  Future<void> upsertService(ServiceItem s);
  Future<void> deleteService(String id);
  Future<void> upsertCategory(Category c);
  Future<void> deleteCategory(String id);
  Future<void> upsertCity(City c);
  Future<void> deleteCity(String id);
}

abstract class BookingRepository {
  Stream<List<Booking>> watchCustomerBookings(String customerId);
  Stream<List<Booking>> watchProviderRequests(String cityId);
  Stream<List<Booking>> watchProviderJobs(String providerId);
  Stream<List<Booking>> watchAll();
  Stream<Booking?> watchBookingById(String id);

  Future<Booking> createBooking({required BookingDraft draft, required AppUser customer});

  /// پذیرش = متخصص یکی از روزها/بازه‌های پیشنهادی مشتری را قطعی می‌کند
  Future<void> accept(String bookingId, ProviderProfile provider,
      {required String day, required String slot});
  Future<void> reject(String bookingId, {String? reason});
  Future<void> advance(String bookingId);
  Future<void> updateStatus(String bookingId, BookingStatus status, {String? note});
  Future<void> cancel(String bookingId);
  Future<void> rate(String bookingId, {required int stars, required String text, required String author});
}

abstract class ProviderRepository {
  Stream<ProviderProfile?> watchProfile(String providerId);
  Stream<List<ProviderProfile>> watchAll();
  Stream<List<EarningEntry>> watchEarnings(String providerId);
  Future<void> setOnline(String providerId, bool online);
  Future<void> setVerified(String providerId, bool verified);

  // ادمین: تعریف/ویرایش/حذف متخصص
  Future<void> upsertProvider(ProviderProfile p);
  Future<void> removeProvider(String providerId); // غیرفعال نرم
}

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchThread(String threadId);
  Future<void> send(String threadId, String text, {bool fromCustomer = true});
}

abstract class MiscRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAllRead(String userId);
  Future<List<AddressItem>> getAddresses(String userId);
  Future<void> addAddress(String userId,
      {required String title, required String text, double lat = 37.55, double lng = 45.07, String cityId = 'urmia', String plaque = ''});
  Stream<double> watchCommission();
  Future<void> setCommission(double v);

  // ⚙️ تنظیمات CMS (تم، شهر پیش‌فرض، کلید AI، شبکه‌ها...)
  Stream<AppSettings> watchSettings();
  Future<void> saveSettings(AppSettings s);

  // 💰 کیف پول واقعی‌نما: شارژ + بونس پلکانی + تراکنش‌ها
  Stream<List<WalletTxn>> watchWallet(String userId);
  Future<({int bonus, int total})> chargeWallet(String userId, int amount);
  Future<bool> payWithWallet(String userId, int amount, String label);

  /// دستیار مشتری (قاعده‌محور آفلاین)
  Future<String> askAssistant(String prompt);

  /// 🤖 کارشناس عیب‌یابی متخصص — اگر کلید Gemini تنظیم شد آنلاین، وگرنه آفلاین
  Future<String> askProviderExpert(String prompt);
}
