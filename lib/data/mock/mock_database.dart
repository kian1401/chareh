/// پیاده‌سازی موک ریپازیتوری‌ها روی MockDb — رفتار «واقعی» (بدون دادهٔ جعلی)
library;

import 'dart:async';

import '../../core/utils/persian_utils.dart';
import '../models.dart';
import '../repositories.dart';
import 'mock_database.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.db);
  final MockDb db;

  @override
  AppUser? get currentUser => db.currentUser;

  @override
  Stream<AppUser?> watchUser() => db.streamOf(() => db.currentUser);

  @override
  Future<String> sendOtp({
    required String phone,
    required UserRole role,
  }) async {
    await db.latency(700);
    // 🔐 قفل پنل مدیریت: فقط شمارهٔ ارشد و مدیران ثبت‌شده
    if (role == UserRole.admin && !db.isAdminPhone(phone)) {
      throw Exception(
        'این شماره در فهرست مدیران نیست؛ فقط مدیر ارشد می‌تواند دسترسی بدهد.',
      );
    }
    db.requestedRole = role.name;
    return db.issueOtp(phone); // 🧪 در حالت تست کد برای نمایش برمی‌گردد
  }

  @override
  Future<AppUser> verifyOtp({
    required String phone,
    required String code,
    String? referralCode,
  }) async {
    await db.latency(700);
    final sent = db.otpCodes[phone];
    if (sent == null)
      throw Exception('کدی برای این شماره صادر نشده؛ ابتدا درخواست کد کنید');
    if (sent != code)
      throw Exception('کد تایید اشتباه است — کد نمایش‌داده‌شده را وارد کنید');
    db.otpCodes.remove(phone);
    final role = UserRoleX.fromName(db.requestedRole);
    if (role == UserRole.admin && !db.isAdminPhone(phone)) {
      throw Exception(
        'این شماره در فهرست مدیران نیست؛ فقط مدیر ارشد می‌تواند دسترسی بدهد.',
      );
    }
    // 📲 رفتار واقعی: هر شماره = یک حساب دائمی (حساب جدید می‌سازد اگر نباشد)
    final user = db.userFromPhone(phone, role, referredBy: referralCode);
    db.currentUser = user;
    db.emit();
    return user;
  }

  @override
  Future<AppUser> signInDemo(UserRole role) async {
    await db.latency(300);
    final user = db.userFromPhone('09140000000', role);
    db.currentUser = user;
    db.emit();
    return user;
  }

  @override
  Future<void> toggleFavorite(String serviceId) async {
    final u = db.currentUser;
    if (u == null) return;
    u.favorites.contains(serviceId)
        ? u.favorites.remove(serviceId)
        : u.favorites.add(serviceId);
    db.emit();
  }

  @override
  Future<void> signOut() async {
    db.currentUser = null;
    db.emit();
  }
}

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository(this.db);
  final MockDb db;

  @override
  Stream<List<Category>> watchCategories({bool includeHidden = false}) =>
      db.streamOf(() {
        final l = includeHidden
            ? db.categories
            : db.categories.where((c) => c.active);
        return (l.toList())..sort((a, b) => a.order.compareTo(b.order));
      });

  @override
  Stream<List<ServiceItem>> watchServices({
    String? categoryId,
    String? query,
    bool includeHidden = false,
  }) => db.streamOf(() => db.services).map((l) {
    var res = includeHidden ? l.toList() : l.where((s) => s.active).toList();
    if (categoryId != null)
      res = res.where((s) => s.categoryId == categoryId).toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      res = res
          .where(
            (s) =>
                s.title.contains(q) ||
                s.description.contains(q) ||
                s.tags.any((t) => t.contains(q)),
          )
          .toList();
    }
    return res;
  });

  @override
  Stream<ServiceItem?> watchService(String id) => db.streamOf(
    () => db.services.where((s) => s.id == id).cast<ServiceItem?>().firstOrNull,
  );

  @override
  Stream<List<Review>> watchReviews(String serviceId) =>
      db.streamOf(() => db.reviewsFor(serviceId));

  @override
  Stream<List<ProviderProfile>> watchProviders({bool activeOnly = true}) =>
      db.streamOf(
        () => activeOnly
            ? db.providers.where((p) => p.active).toList()
            : db.providers,
      );

  @override
  Stream<List<City>> watchCities({bool activeOnly = true}) => db.streamOf(
    () => activeOnly ? db.cities.where((c) => c.active).toList() : db.cities,
  );

  @override
  Future<void> upsertService(ServiceItem s) async {
    await db.latency(150);
    final i = db.services.indexWhere((e) => e.id == s.id);
    i >= 0 ? db.services[i] = s : db.services.add(s);
    db.emit();
  }

  @override
  Future<void> deleteService(String id) async {
    await db.latency(150);
    db.services.removeWhere((s) => s.id == id);
    db.emit();
  }

  @override
  Future<void> upsertCategory(Category c) async {
    await db.latency(150);
    final i = db.categories.indexWhere((e) => e.id == c.id);
    i >= 0 ? db.categories[i] = c : db.categories.add(c);
    db.emit();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await db.latency(150);
    db.categories.removeWhere((c) => c.id == id);
    db.emit();
  }

  @override
  Future<void> upsertCity(City c) async {
    await db.latency(120);
    final i = db.cities.indexWhere((e) => e.id == c.id);
    i >= 0 ? db.cities[i] = c : db.cities.add(c);
    db.emit();
  }

  @override
  Future<void> deleteCity(String id) async {
    await db.latency(120);
    db.cities.removeWhere((e) => e.id == id);
    db.emit();
  }
}

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this.db);
  final MockDb db;

  List<Booking> _sorted(Iterable<Booking> l) =>
      l.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Booking>> watchCustomerBookings(String customerId) => db.streamOf(
    () => _sorted(db.bookings.where((b) => b.customerId == customerId)),
  );

  @override
  Stream<List<Booking>> watchProviderRequests(String cityId) => db.streamOf(
    () => _sorted(
      db.bookings.where(
        (b) =>
            b.providerId == null &&
            b.status == BookingStatus.pending &&
            b.cityId == cityId,
      ),
    ),
  );

  @override
  Stream<List<Booking>> watchProviderJobs(String providerId) => db.streamOf(
    () => _sorted(db.bookings.where((b) => b.providerId == providerId)),
  );

  @override
  Stream<List<Booking>> watchAll() => db.streamOf(() => _sorted(db.bookings));

  @override
  Stream<Booking?> watchBookingById(String id) => db.streamOf(
    () => db.bookings.where((b) => b.id == id).cast<Booking?>().firstOrNull,
  );

  Booking _find(String id) => db.bookings.firstWhere((b) => b.id == id);

  @override
  Future<Booking> createBooking({
    required BookingDraft draft,
    required AppUser customer,
  }) async {
    await db.latency(400);
    final s = draft.service!;
    final b = Booking(
      id: db.nextId('b'),
      serviceId: s.id,
      serviceTitle: s.title,
      serviceEmoji: s.emoji,
      optionTitle: draft.option!.title,
      addOnTitles: [
        for (final a in s.addOns)
          if (draft.addOnIds.contains(a.id)) a.title,
      ],
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone, // 🔒 قبل از پذیرش ماسک می‌شود
      cityId: draft.cityId,
      dayLabel: draft.days.join('، '),
      timeSlot: draft.slots.join('، '),
      candidateDays: draft.days.toList(),
      candidateSlots: draft.slots.toList(),
      addressText: '${draft.address!.title} — ${draft.address!.fullText}',
      addressLat: draft.address!.lat,
      addressLng: draft.address!.lng,
      totalPrice: draft.total,
      paymentMethod: draft.paymentMethod,
    );
    // 💳 پرداخت از کیف پول (واقعی‌نما)
    if (draft.paymentMethod == 'کیف پول') {
      if (customer.walletBalance < draft.total) {
        throw Exception('موجودی کیف پول کافی نیست');
      }
      customer.walletBalance -= draft.total;
      db.walletTxns.add(
        WalletTxn(
          id: db.nextId('w'),
          userId: customer.id,
          title: 'پرداخت سفارش ${s.title}',
          amount: -draft.total,
          at: DateTime.now(),
        ),
      );
    }
    db.bookings.add(b);
    db.notifications.insert(
      0,
      AppNotification(
        id: db.nextId('n'),
        title: 'سفارش ثبت شد 🎉',
        emoji: '🎉',
        at: DateTime.now(),
        body:
            '${s.title} — ${b.candidateDays.length} روز پیشنهادی. متخصصِ شهر شما مناسب‌ترین زمان را نهایی می‌کند.',
      ),
    );
    db.emit();
    return b;
  }

  @override
  Future<void> accept(
    String bookingId,
    ProviderProfile provider, {
    required String day,
    required String slot,
  }) async {
    await db.latency(250);
    _find(bookingId)
      ..providerId = provider.id
      ..providerName = provider.name
      ..providerEmoji = provider.emoji
      ..confirmedDay = day
      ..confirmedSlot = slot
      ..contactRevealed =
          true // پس از پذیرش پل ارتباط باز است (ضد دور زدن: همه چیز لیمیت‌دار)
      ..status = BookingStatus.accepted
      ..timeline.add(
        StatusEvent(
          BookingStatus.accepted,
          DateTime.now(),
          note: 'زمان نهایی: $day، $slot',
        ),
      );
    db.emit();
  }

  @override
  Future<void> reject(String bookingId, {String? reason}) async {
    await db.latency(150);
    _find(bookingId)
      ..status = BookingStatus.rejected
      ..timeline.add(
        StatusEvent(BookingStatus.rejected, DateTime.now(), note: reason),
      );
    db.emit();
  }

  @override
  Future<void> advance(String bookingId) async {
    final next = _find(bookingId).status.next;
    if (next != null) await updateStatus(bookingId, next);
  }

  @override
  Future<void> updateStatus(
    String bookingId,
    BookingStatus status, {
    String? note,
  }) async {
    await db.latency(150);
    final b = _find(bookingId)
      ..status = status
      ..timeline.add(StatusEvent(status, DateTime.now(), note: note));
    // 💰 پرداخت کامل به متخصص: ورود درآمد هنگام تکمیل واقعی‌نما (حالا با کمیسیون پلتفرم تمیز)
    if (status == BookingStatus.completed && b.providerId != null) {
      final net = (b.totalPrice * (1 - db.settings.commissionRate)).round();
      db.earnings.add(
        EarningEntry(
          id: db.nextId('e'),
          title:
              'تسویهٔ «${b.serviceTitle}» — ${b.confirmedDay ?? b.dayLabel} ${b.confirmedSlot ?? b.timeSlot}',
          dateLabel: faDayLabel(DateTime.now()),
          amount: net,
          settled: true,
        ),
      );
      db.emit();
    }
  }

  @override
  Future<void> cancel(String bookingId) =>
      updateStatus(bookingId, BookingStatus.cancelled);

  @override
  Future<void> rate(
    String bookingId, {
    required int stars,
    required String text,
    required String author,
  }) async {
    await db.latency(150);
    final b = _find(bookingId)
      ..rating = stars
      ..review = text;
    // ⭐ امتیاز تمام‌عمری متخصص + سرویس هر دو واقعی به‌روز می‌شوند
    final p = db.providers.where((e) => e.id == b.providerId).firstOrNull;
    if (p != null) {
      p.rating = ((p.rating * p.ratingCount) + stars) / (p.ratingCount + 1);
      p.ratingCount++;
      p.jobsDone++;
    }
    final svc = db.services.where((s) => s.id == b.serviceId).firstOrNull;
    if (svc != null) {
      svc.rating =
          ((svc.rating * svc.ratingCount) + stars) / (svc.ratingCount + 1);
      svc.ratingCount++;
      svc.jobsDone++;
    }
    db.emit();
  }
}

class MockProviderRepository implements ProviderRepository {
  MockProviderRepository(this.db);
  final MockDb db;

  @override
  Stream<ProviderProfile?> watchProfile(String providerId) => db.streamOf(
    () => db.providers
        .where((p) => p.id == providerId)
        .cast<ProviderProfile?>()
        .firstOrNull,
  );

  @override
  Stream<List<ProviderProfile>> watchAll() => db.streamOf(() => db.providers);

  @override
  Stream<List<EarningEntry>> watchEarnings(String providerId) =>
      db.streamOf(() => db.earnings);

  @override
  Future<void> setOnline(String providerId, bool online) async {
    await db.latency(120);
    final p = db.providers.where((e) => e.id == providerId).firstOrNull;
    if (p != null) {
      p.online = online;
      db.emit();
    }
  }

  @override
  Future<void> setVerified(String providerId, bool verified) async {
    await db.latency(120);
    final p = db.providers.where((e) => e.id == providerId).firstOrNull;
    if (p != null) {
      p.verified = verified;
      db.emit();
    }
  }

  @override
  Future<void> upsertProvider(ProviderProfile p) async {
    await db.latency(150);
    final i = db.providers.indexWhere((e) => e.id == p.id);
    i >= 0 ? db.providers[i] = p : db.providers.add(p);
    db.emit();
  }

  @override
  Future<void> removeProvider(String providerId) async {
    await db.latency(150);
    final p = db.providers.where((e) => e.id == providerId).firstOrNull;
    if (p != null) {
      p.active = false;
      p.online = false;
      db.emit();
    }
  }
}

class MockChatRepository implements ChatRepository {
  MockChatRepository(this.db);
  final MockDb db;

  @override
  Stream<List<ChatMessage>> watchThread(String threadId) =>
      db.streamOf(() => db.threads[threadId] ?? []);

  @override
  Future<void> send(
    String threadId,
    String text, {
    bool fromCustomer = true,
  }) async {
    final list = db.threads.putIfAbsent(threadId, () => []);
    list.add(
      ChatMessage(
        id: db.nextId('m'),
        threadId: threadId,
        isMine: true,
        text: text,
        at: DateTime.now(),
      ),
    );
    db.emit();
    unawaited(
      Future.delayed(const Duration(seconds: 1), () {
        list.add(
          ChatMessage(
            id: db.nextId('m'),
            threadId: threadId,
            isMine: false,
            text: fromCustomer
                ? 'بله حتماً 👍 ممنون از هماهنگی شما.'
                : 'متشکرم، انجام شد ✅',
            at: DateTime.now(),
          ),
        );
        db.emit();
      }),
    );
  }
}

class MockMiscRepository implements MiscRepository {
  MockMiscRepository(this.db);
  final MockDb db;

  @override
  Stream<List<String>> watchAdminPhones() =>
      db.streamOf(() => (db.adminPhones.toList()..sort()));

  @override
  Future<void> addAdminPhone(String phone) async {
    db.adminPhones.add(phone);
    db.emit();
  }

  @override
  Future<void> removeAdminPhone(String phone) async {
    if (phone == MockDb.masterAdminPhone)
      throw Exception('شمارهٔ مدیر ارشد قابل حذف نیست');
    db.adminPhones.remove(phone);
    db.emit();
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      db.streamOf(() => db.notifications);

  @override
  Future<void> markAllRead(String userId) async {
    for (final n in db.notifications) {
      n.unread = false;
    }
    db.emit();
  }

  @override
  Future<List<AddressItem>> getAddresses(String userId) async =>
      db.addresses[userId] ?? [];

  @override
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
  }) async {
    final list = db.addresses.putIfAbsent(userId, () => []);
    list.add(
      AddressItem(
        id: db.nextId('ad'),
        title: title,
        text: text,
        lat: lat,
        lng: lng,
        cityId: cityId,
        plaque: plaque,
        floor: floor,
        unit: unit,
      ),
    );
    db.emit();
  }

  @override
  Stream<double> watchCommission() =>
      db.streamOf(() => db.settings.commissionRate);

  @override
  Future<void> setCommission(double v) async {
    db.settings.commissionRate = v;
    db.emit();
  }

  @override
  Stream<AppSettings> watchSettings() => db.streamOf(() => db.settings);

  @override
  Future<void> saveSettings(AppSettings s) async {
    db.settings
      ..appTitle = s.appTitle
      ..primaryHex = s.primaryHex
      ..fontFamily = s.fontFamily
      ..heroImageUrl = s.heroImageUrl
      ..logoEmoji = s.logoEmoji
      ..geminiApiKey = s.geminiApiKey
      ..defaultCityId = s.defaultCityId
      ..bonusTiers = s.bonusTiers
      ..referralReward = s.referralReward
      ..commissionRate = s.commissionRate
      ..telegramUrl = s.telegramUrl
      ..instagramUrl = s.instagramUrl
      ..whatsappUrl = s.whatsappUrl
      ..socialOrderComingSoon = s.socialOrderComingSoon;
    db.emit();
  }

  @override
  Stream<List<WalletTxn>> watchWallet(String userId) => db.streamOf(
    () =>
        (db.walletTxns.where((t) => t.userId == userId).toList())
          ..sort((a, b) => b.at.compareTo(a.at)),
  );

  @override
  Future<({int bonus, int total})> chargeWallet(
    String userId,
    int amount,
  ) async {
    await db.latency(700);
    final u = db.usersByPhone.values.where((e) => e.id == userId).firstOrNull;
    if (u == null) return (bonus: 0, total: amount);
    // 🎁 بونس پلکانی طبق تنظیمات ادمین
    var percent = 0;
    for (final t in db.settings.bonusTiers) {
      if (amount >= t.minAmount && t.bonusPercent > percent)
        percent = t.bonusPercent;
    }
    final bonus = (amount * percent / 100).round();
    u.walletBalance += amount + bonus;
    u.points += (amount / 10000).floor();
    db.walletTxns.add(
      WalletTxn(
        id: db.nextId('w'),
        userId: userId,
        title: 'شارژ کیف پول 💳',
        amount: amount,
        at: DateTime.now(),
      ),
    );
    if (bonus > 0) {
      db.walletTxns.add(
        WalletTxn(
          id: db.nextId('w'),
          userId: userId,
          title: 'هدیهٔ شارژ ویژه ${percent.toString()}٪ 🎁',
          amount: bonus,
          isBonus: true,
          at: DateTime.now(),
        ),
      );
    }
    db.emit();
    return (bonus: bonus, total: amount + bonus);
  }

  @override
  Future<bool> payWithWallet(String userId, int amount, String label) async {
    final u = db.usersByPhone.values.where((e) => e.id == userId).firstOrNull;
    if (u == null || u.walletBalance < amount) return false;
    u.walletBalance -= amount;
    db.walletTxns.add(
      WalletTxn(
        id: db.nextId('w'),
        userId: userId,
        title: label,
        amount: -amount,
        at: DateTime.now(),
      ),
    );
    db.emit();
    return true;
  }

  @override
  Future<String> askAssistant(String prompt) async {
    await db.latency(900);
    return db.assistantReply(prompt);
  }

  @override
  Future<String> askProviderExpert(String prompt) async {
    // اگر کلید Gemini تنظیم شده باشد، فاز بعدی به API واقعی وصل می‌شود؛ فعلاً کارشناس آفلاین
    await db.latency(1100);
    return db.providerAiReply(prompt);
  }
}
