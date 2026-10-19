/// پیاده‌سازی موک ریپازیتوری‌ها روی MockDb
library;

import 'dart:async';

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
  Future<void> sendOtp({required String phone, required UserRole role}) async {
    await db.latency(600);
    db.requestedRole = role.name;
  }

  @override
  Future<AppUser> verifyOtp({required String phone, required String code}) async {
    await db.latency(600);
    if (code.length != 6) {
      throw Exception('کد تایید باید ۶ رقم باشد');
    }
    final role = switch (db.requestedRole) {
      'provider' => 'u_p1',
      'admin' => 'u_a1',
      _ => 'u_c1',
    };
    final user = db.demoUsers[role]!..phone = phone;
    db.currentUser = user;
    db.emit();
    return user;
  }

  @override
  Future<AppUser> signInDemo(UserRole role) async {
    await db.latency(200);
    final id = switch (role) {
      UserRole.provider => 'u_p1',
      UserRole.admin => 'u_a1',
      _ => 'u_c1',
    };
    db.currentUser = db.demoUsers[id];
    db.emit();
    return db.currentUser!;
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
  Stream<List<Category>> watchCategories() =>
      db.streamOf(() => db.categories).map((l) => l.where((c) => c.active).toList());

  // برای ادمین: همه حتی غیرفعال — در UI از watchServices استفاده می‌کنیم که فیلتر خودش را دارد
  @override
  Stream<List<ServiceItem>> watchServices({String? categoryId, String? query}) =>
      db.streamOf(() => db.services).map((l) {
        var res = l.toList();
        if (categoryId != null) res = res.where((s) => s.categoryId == categoryId).toList();
        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim();
          res = res
              .where((s) =>
                  s.title.contains(q) || s.description.contains(q) || s.tags.any((t) => t.contains(q)))
              .toList();
        }
        return res;
      });

  @override
  Stream<ServiceItem?> watchService(String id) => db.streamOf(
      () => db.services.where((s) => s.id == id).cast<ServiceItem?>().firstOrNull);

  @override
  Stream<List<Review>> watchReviews(String serviceId) =>
      db.streamOf(() => db.reviewsFor(serviceId));

  @override
  Stream<List<ProviderProfile>> watchProviders() => db.streamOf(() => db.providers);

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
}

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this.db);
  final MockDb db;

  List<Booking> _sorted(Iterable<Booking> l) =>
      l.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Booking>> watchCustomerBookings(String customerId) =>
      db.streamOf(() => _sorted(db.bookings.where((b) => b.customerId == customerId)));

  @override
  Stream<List<Booking>> watchProviderRequests() => db.streamOf(() =>
      _sorted(db.bookings.where((b) => b.providerId == null && b.status == BookingStatus.pending)));

  @override
  Stream<List<Booking>> watchProviderJobs(String providerId) =>
      db.streamOf(() => _sorted(db.bookings.where((b) => b.providerId == providerId)));

  @override
  Stream<List<Booking>> watchAll() => db.streamOf(() => _sorted(db.bookings));

  @override
  Stream<Booking?> watchBookingById(String id) => db.streamOf(
      () => db.bookings.where((b) => b.id == id).cast<Booking?>().firstOrNull);

  Booking _find(String id) => db.bookings.firstWhere((b) => b.id == id);

  @override
  Future<Booking> createBooking({required BookingDraft draft, required AppUser customer}) async {
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
          if (draft.addOnIds.contains(a.id)) a.title
      ],
      customerId: customer.id,
      customerName: customer.name,
      dayLabel: draft.dayLabel,
      timeSlot: draft.timeSlot!,
      addressText: '${draft.address!.title} — ${draft.address!.text}',
      totalPrice: draft.total,
      paymentMethod: draft.paymentMethod,
    );
    db.bookings.add(b);
    db.notifications.insert(
      0,
      AppNotification(
        id: db.nextId('n'),
        title: 'سفارش ثبت شد 🎉',
        body: '${s.title} برای ${b.dayLabel} ${b.timeSlot}. به‌محض پذیرش متخصص اطلاع می‌دهیم.',
        emoji: '🎉',
        at: DateTime.now(),
      ),
    );
    db.emit();
    return b;
  }

  @override
  Future<void> accept(String bookingId, ProviderProfile provider) async {
    await db.latency(200);
    _find(bookingId)
      ..providerId = provider.id
      ..providerName = provider.name
      ..providerEmoji = provider.emoji
      ..status = BookingStatus.accepted
      ..timeline.add(StatusEvent(BookingStatus.accepted, DateTime.now()));
    db.emit();
  }

  @override
  Future<void> reject(String bookingId, {String? reason}) async {
    await db.latency(200);
    _find(bookingId)
      ..status = BookingStatus.rejected
      ..timeline.add(StatusEvent(BookingStatus.rejected, DateTime.now(), note: reason));
    db.emit();
  }

  @override
  Future<void> advance(String bookingId) async {
    final next = _find(bookingId).status.next;
    if (next != null) await updateStatus(bookingId, next);
  }

  @override
  Future<void> updateStatus(String bookingId, BookingStatus status, {String? note}) async {
    await db.latency(200);
    _find(bookingId)
      ..status = status
      ..timeline.add(StatusEvent(status, DateTime.now(), note: note));
    db.emit();
  }

  @override
  Future<void> cancel(String bookingId) =>
      updateStatus(bookingId, BookingStatus.cancelled);

  @override
  Future<void> rate(String bookingId,
      {required int stars, required String text, required String author}) async {
    await db.latency(200);
    final b = _find(bookingId)
      ..rating = stars
      ..review = text;
    // به‌روزرسانی تقریبی امتیاز سرویس
    final svc = db.services.where((s) => s.id == b.serviceId).firstOrNull;
    if (svc != null) {
      svc.rating = ((svc.rating * svc.ratingCount) + stars) / (svc.ratingCount + 1);
      svc.ratingCount++;
    }
    db.emit();
  }
}

class MockProviderRepository implements ProviderRepository {
  MockProviderRepository(this.db);
  final MockDb db;

  @override
  Stream<ProviderProfile?> watchProfile(String providerId) => db.streamOf(
      () => db.providers.where((p) => p.id == providerId).cast<ProviderProfile?>().firstOrNull);

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
}

class MockChatRepository implements ChatRepository {
  MockChatRepository(this.db);
  final MockDb db;

  @override
  Stream<List<ChatMessage>> watchThread(String threadId) =>
      db.streamOf(() => db.threads[threadId] ?? []);

  @override
  Future<void> send(String threadId, String text, {bool fromCustomer = true}) async {
    final list = db.threads.putIfAbsent(threadId, () => []);
    list.add(ChatMessage(
      id: db.nextId('m'),
      threadId: threadId,
      isMine: true,
      text: text,
      at: DateTime.now(),
    ));
    db.emit();
    // پاسخ خودکار شبیه‌سازی‌شده
    unawaited(Future.delayed(const Duration(seconds: 1), () {
      list.add(ChatMessage(
        id: db.nextId('m'),
        threadId: threadId,
        isMine: false,
        text: fromCustomer
            ? 'بله حتماً 👍 ممنون از هماهنگی شما.'
            : 'متشکرم، انجام شد ✅',
        at: DateTime.now(),
      ));
      db.emit();
    }));
  }
}

class MockMiscRepository implements MiscRepository {
  MockMiscRepository(this.db);
  final MockDb db;

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
      db.addresses[userId] ?? db.addresses['u_c1']!;

  @override
  Future<void> addAddress(String userId, {required String title, required String text}) async {
    final list = db.addresses.putIfAbsent(userId.isEmpty ? 'u_c1' : userId, () => []);
    list.add(AddressItem(id: db.nextId('ad'), title: title, text: text));
    db.emit();
  }

  @override
  Stream<double> watchCommission() => db.streamOf(() => db.commissionRate);

  @override
  Future<void> setCommission(double v) async {
    db.commissionRate = v;
    db.emit();
  }

  @override
  Future<String> askAssistant(String prompt) async {
    await db.latency(900);
    return db.assistantReply(prompt);
  }
}
