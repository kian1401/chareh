/// اینترفیس‌های بک‌اند — پیاده‌سازی موک و Firebase هر دو همین قرارداد را اجرا می‌کنند.
library;

import 'models.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchUser();

  Future<void> sendOtp({required String phone, required UserRole role});
  Future<AppUser> verifyOtp({required String phone, required String code});

  /// ورود سریع دمو (فقط حالت موک)
  Future<AppUser> signInDemo(UserRole role);

  Future<void> toggleFavorite(String serviceId);
  Future<void> signOut();
}

abstract class CatalogRepository {
  Stream<List<Category>> watchCategories();
  Stream<List<ServiceItem>> watchServices({String? categoryId, String? query});
  Stream<ServiceItem?> watchService(String id);
  Stream<List<Review>> watchReviews(String serviceId);
  Stream<List<ProviderProfile>> watchProviders();

  // مدیریت (ادمین)
  Future<void> upsertService(ServiceItem s);
  Future<void> deleteService(String id);
  Future<void> upsertCategory(Category c);
  Future<void> deleteCategory(String id);
}

abstract class BookingRepository {
  Stream<List<Booking>> watchCustomerBookings(String customerId);
  Stream<List<Booking>> watchProviderRequests(); // سفارش‌های باز بازار (در انتظار پذیرش)
  Stream<List<Booking>> watchProviderJobs(String providerId);
  Stream<List<Booking>> watchAll(); // ادمین
  Stream<Booking?> watchBookingById(String id);

  Future<Booking> createBooking({required BookingDraft draft, required AppUser customer});
  Future<void> accept(String bookingId, ProviderProfile provider);
  Future<void> reject(String bookingId, {String? reason});
  Future<void> advance(String bookingId); // گام بعدی وضعیت
  Future<void> updateStatus(String bookingId, BookingStatus status, {String? note});
  Future<void> cancel(String bookingId);
  Future<void> rate(String bookingId, {required int stars, required String text, required String author});
}

abstract class ProviderRepository {
  Stream<ProviderProfile?> watchProfile(String providerId);
  Stream<List<EarningEntry>> watchEarnings(String providerId);
  Future<void> setOnline(String providerId, bool online);
  Future<void> setVerified(String providerId, bool verified);
}

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchThread(String threadId);
  Future<void> send(String threadId, String text, {bool fromCustomer = true});
}

abstract class MiscRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAllRead(String userId);
  Future<List<AddressItem>> getAddresses(String userId);
  Future<void> addAddress(String userId, {required String title, required String text});
  Stream<double> watchCommission(); // درصد کمیسیون پلتفرم
  Future<void> setCommission(double v);

  /// دستیار هوشمند (Gemini روی Cloud Functions — در حالت موک: پاسخ قاعده‌محور)
  Future<String> askAssistant(String prompt);
}
