/// پیاده‌سازی Firebase ریپازیتوری‌ها
/// فعال‌سازی: BackendConfig.useMock = false + اجرای flutterfire configure
/// ساختار داده: docs/SCHEMA.md را ببینید.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';
import '../repositories.dart';

/// نرمال‌سازی داده‌ی Firestore (Timestamp → ISO) برای مدل‌ها
Map<String, dynamic> _norm(Map<String, dynamic> j) {
  final out = <String, dynamic>{};
  j.forEach((k, v) {
    if (v is Timestamp) {
      out[k] = v.toDate().toIso8601String();
    } else if (v is List) {
      out[k] = v
          .map((e) => e is Map
              ? Map<String, dynamic>.from(e).map((k2, v2) =>
                  MapEntry(k2, v2 is Timestamp ? v2.toDate().toIso8601String() : v2))
              : e)
          .toList();
    } else {
      out[k] = v;
    }
  });
  return out;
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository() {
    _auth.authStateChanges().listen((_) => _cached = _userFromFirebase(_auth.currentUser));
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _fn = FirebaseFunctions.instance;

  AppUser? _cached;

  AppUser? _userFromFirebase(User? u) => null; // داده‌ی کامل از users/{uid} خوانده می‌شود

  @override
  AppUser? get currentUser => _cached;

  @override
  Stream<AppUser?> watchUser() => _auth.authStateChanges().asyncExpand((fuser) {
        if (fuser == null) return Stream<AppUser?>.value(null);
        return _db.collection('users').doc(fuser.uid).snapshots().map((snap) {
          if (!snap.exists) return null;
          final user = AppUser.fromJson(snap.id, _norm(snap.data()!));
          _cached = user;
          return user;
        });
      });

  @override
  Future<String> sendOtp({required String phone, required UserRole role}) async {
    final res = await _fn.httpsCallable('sendOtp').call({'phone': phone, 'role': role.name});
    return (res.data?['code'] ?? '').toString();
  }

  @override
  Future<AppUser> verifyOtp({required String phone, required String code, String? referralCode}) async {
    final res = await _fn
        .httpsCallable('verifyOtp')
        .call({'phone': phone, 'code': code, 'role': null});
    final token = res.data['token'] as String;
    await _auth.signInWithCustomToken(token);
    final doc = await _db.collection('users').doc(_auth.currentUser!.uid).get();
    return AppUser.fromJson(doc.id, _norm(doc.data()!));
  }

  @override
  Future<AppUser> signInDemo(UserRole role) =>
      throw StateError('ورود دمو فقط در حالت موک فعال است.');

  @override
  Future<void> toggleFavorite(String serviceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final favs = List<String>.from(snap.data()?['favorites'] ?? []);
    favs.contains(serviceId) ? favs.remove(serviceId) : favs.add(serviceId);
    await ref.update({'favorites': favs});
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseCatalogRepository implements CatalogRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<Category>> watchCategories({bool includeHidden = false}) => (includeHidden
          ? _db.collection('categories')
          : _db.collection('categories').where('active', isEqualTo: true))
      .snapshots()
      .map((q) => q.docs.map((d) => Category.fromJson(d.id, _norm(d.data()))).toList())
      .map((l) { l.sort((a, b) => a.order.compareTo(b.order)); return l; });

  @override
  Stream<List<ServiceItem>> watchServices({String? categoryId, String? query, bool includeHidden = false}) {
    Query<Map<String, dynamic>> ref = _db.collection('services');
    if (categoryId != null) ref = ref.where('categoryId', isEqualTo: categoryId);
    // جستجوی متنی در حالت واقعی را Algolia/Elastic انجام می‌دهد؛ اینجا فیلتر سمت کلاینت کافی است
    return ref.snapshots().map((q) {
      var list = q.docs.map((d) => ServiceItem.fromJson(d.id, _norm(d.data()))).toList();
      if (query != null && query.trim().isNotEmpty) {
        final s = query.trim();
        list = list
            .where((e) =>
                e.title.contains(s) || e.description.contains(s) || e.tags.any((t) => t.contains(s)))
            .toList();
      }
      return list;
    });
  }

  @override
  Stream<ServiceItem?> watchService(String id) => _db
      .collection('services')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ServiceItem.fromJson(d.id, _norm(d.data()!)) : null);

  @override
  Stream<List<Review>> watchReviews(String serviceId) => _db
      .collection('reviews')
      .where('serviceId', isEqualTo: serviceId)
      .orderBy('at', descending: true)
      .limit(30)
      .snapshots()
      .map((q) => q.docs.map((d) => Review.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Stream<List<ProviderProfile>> watchProviders({bool activeOnly = true}) => (activeOnly
          ? _db.collection('providers').where('active', isEqualTo: true)
          : _db.collection('providers'))
      .snapshots()
      .map((q) => q.docs.map((d) => ProviderProfile.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Stream<List<City>> watchCities({bool activeOnly = true}) => (activeOnly
          ? _db.collection('cities').where('active', isEqualTo: true)
          : _db.collection('cities'))
      .snapshots()
      .map((q) => q.docs.map((d) => City.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Future<void> upsertCity(City c) =>
      _db.collection('cities').doc(c.id).set(c.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteCity(String id) => _db.collection('cities').doc(id).delete();

  @override
  Future<void> upsertService(ServiceItem s) =>
      _db.collection('services').doc(s.id).set(s.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteService(String id) => _db.collection('services').doc(id).delete();

  @override
  Future<void> upsertCategory(Category c) =>
      _db.collection('categories').doc(c.id).set(c.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteCategory(String id) => _db.collection('categories').doc(id).delete();
}

class FirebaseBookingRepository implements BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('bookings');

  List<Booking> _map(QuerySnapshot<Map<String, dynamic>> q) => q.docs
      .map((d) => Booking.fromJson(d.id, _norm(d.data())))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Booking>> watchCustomerBookings(String customerId) =>
      _col.where('customerId', isEqualTo: customerId).snapshots().map(_map);

  @override
  Stream<List<Booking>> watchProviderRequests(String cityId) => _col
      .where('providerId', isNull: true)
      .where('status', isEqualTo: 'pending')
      .where('cityId', isEqualTo: cityId)
      .snapshots()
      .map(_map);

  @override
  Stream<List<Booking>> watchProviderJobs(String providerId) =>
      _col.where('providerId', isEqualTo: providerId).snapshots().map(_map);

  @override
  Stream<List<Booking>> watchAll() => _col.snapshots().map(_map);

  @override
  Stream<Booking?> watchBookingById(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Booking.fromJson(d.id, _norm(d.data()!)) : null);

  @override
  Future<Booking> createBooking({required BookingDraft draft, required AppUser customer}) async {
    final s = draft.service!;
    final data = Booking(
      id: '',
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
      customerPhone: customer.phone,
      cityId: draft.cityId,
      dayLabel: draft.days.join('، '),
      timeSlot: draft.slots.join('، '),
      candidateDays: draft.days.toList(),
      candidateSlots: draft.slots.toList(),
      addressText: '${draft.address!.title} — ${draft.address!.text}',
      addressLat: draft.address!.lat,
      addressLng: draft.address!.lng,
      totalPrice: draft.total,
      paymentMethod: draft.paymentMethod,
    ).toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['timeline'] = [
      {'status': 'pending', 'at': DateTime.now().toIso8601String()}
    ];
    final ref = await _col.add(data);
    final snap = await ref.get();
    return Booking.fromJson(ref.id, _norm(snap.data()!));
  }

  @override
  Future<void> accept(String bookingId, ProviderProfile provider, {required String day, required String slot}) =>
      _col.doc(bookingId).update({
        'providerId': provider.id,
        'providerName': provider.name,
        'providerEmoji': provider.emoji,
        'confirmedDay': day,
        'confirmedSlot': slot,
        'contactRevealed': true,
        'status': 'accepted',
        'timeline': FieldValue.arrayUnion([
          {'status': 'accepted', 'at': DateTime.now().toIso8601String(), 'note': 'زمان نهایی: $day، $slot'}
        ]),
      });

  @override
  Future<void> reject(String bookingId, {String? reason}) => _col.doc(bookingId).update({
        'status': 'rejected',
        'timeline': FieldValue.arrayUnion([
          {'status': 'rejected', 'at': DateTime.now().toIso8601String(), 'note': reason}
        ]),
      });

  @override
  Future<void> advance(String bookingId) async {
    final snap = await _col.doc(bookingId).get();
    final status = BookingStatusX.fromName(snap.data()?['status']);
    final next = status.next;
    if (next != null) await updateStatus(bookingId, next);
  }

  @override
  Future<void> updateStatus(String bookingId, BookingStatus status, {String? note}) async =>
      _col.doc(bookingId).update({
        'status': status.name,
        'timeline': FieldValue.arrayUnion([
          {'status': status.name, 'at': DateTime.now().toIso8601String(), if (note != null) 'note': note}
        ]),
      });

  @override
  Future<void> cancel(String bookingId) => updateStatus(bookingId, BookingStatus.cancelled);

  @override
  Future<void> rate(String bookingId,
      {required int stars, required String text, required String author}) {
    return _col.doc(bookingId).update(
        {'rating': stars, 'review': text, 'reviewedAt': FieldValue.serverTimestamp()});
    // تجمیع امتیاز سرویس توسط Cloud Functionِ onReviewUpdate انجام می‌شود
  }
}

class FirebaseProviderRepository implements ProviderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<ProviderProfile?> watchProfile(String providerId) => _db
      .collection('providers')
      .doc(providerId)
      .snapshots()
      .map((d) => d.exists ? ProviderProfile.fromJson(d.id, _norm(d.data()!)) : null);

  @override
  Stream<List<ProviderProfile>> watchAll() => _db
      .collection('providers')
      .snapshots()
      .map((q) => q.docs.map((d) => ProviderProfile.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Future<void> upsertProvider(ProviderProfile p) =>
      _db.collection('providers').doc(p.id).set(p.toJson(), SetOptions(merge: true));

  @override
  Future<void> removeProvider(String providerId) =>
      _db.collection('providers').doc(providerId).update({'active': false, 'online': false});

  @override
  Stream<List<EarningEntry>> watchEarnings(String providerId) => _db
      .collection('earnings')
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((q) => q.docs.map((d) => EarningEntry.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Future<void> setOnline(String providerId, bool online) =>
      _db.collection('providers').doc(providerId).update({'online': online});

  @override
  Future<void> setVerified(String providerId, bool verified) =>
      _db.collection('providers').doc(providerId).update({'verified': verified});
}

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<ChatMessage>> watchThread(String threadId) => _db
      .collection('threads')
      .doc(threadId)
      .collection('messages')
      .orderBy('at')
      .snapshots()
      .map((q) => q.docs.map((d) => ChatMessage.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Future<void> send(String threadId, String text, {bool fromCustomer = true}) => _db
      .collection('threads')
      .doc(threadId)
      .collection('messages')
      .add({'threadId': threadId, 'isMine': true, 'text': text, 'at': FieldValue.serverTimestamp()});
}

class FirebaseMiscRepository implements MiscRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _fn = FirebaseFunctions.instance;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => _db
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((q) => q.docs.map((d) => AppNotification.fromJson(d.id, _norm(d.data()))).toList());

  @override
  Future<void> markAllRead(String userId) async {
    final q = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('unread', isEqualTo: true)
        .get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'unread': false});
    }
    await batch.commit();
  }

  @override
  Future<List<AddressItem>> getAddresses(String userId) async {
    final q = await _db.collection('users').doc(userId).collection('addresses').get();
    return q.docs.map((d) => AddressItem.fromJson(d.id, _norm(d.data()))).toList();
  }

  @override
  Future<void> addAddress(String userId,
          {required String title, required String text, double lat = 37.55, double lng = 45.07, String cityId = 'urmia', String plaque = '', String floor = '', String unit = ''}) =>
      _db.collection('users').doc(userId).collection('addresses').add({
        'title': title, 'text': text, 'lat': lat, 'lng': lng, 'cityId': cityId, 'plaque': plaque, 'floor': floor, 'unit': unit, 'isDefault': false,
      });

  @override
  Stream<AppSettings> watchSettings() => _db
      .collection('settings')
      .doc('app')
      .snapshots()
      .map((d) => d.exists ? AppSettings.fromJson(_norm(d.data()!)) : AppSettings());

  @override
  Future<void> saveSettings(AppSettings st) =>
      _db.collection('settings').doc('app').set(st.toJson(), SetOptions(merge: true));

  @override
  Stream<List<WalletTxn>> watchWallet(String userId) => _db
      .collection('walletTxns')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((q) => (q.docs.map((d) => WalletTxn.fromJson(d.id, _norm(d.data()))).toList())
        ..sort((a, b) => b.at.compareTo(a.at)));

  @override
  Future<({int bonus, int total})> chargeWallet(String userId, int amount) async {
    final res = await _fn.httpsCallable('chargeWallet').call({'userId': userId, 'amount': amount});
    return (bonus: (res.data?['bonus'] ?? 0) as int, total: (res.data?['total'] ?? amount) as int);
  }

  @override
  Future<bool> payWithWallet(String userId, int amount, String label) async {
    final res = await _fn
        .httpsCallable('payWithWallet')
        .call({'userId': userId, 'amount': amount, 'label': label});
    return res.data?['ok'] == true;
  }

  @override
  Future<String> askProviderExpert(String prompt) async {
    final res = await _fn.httpsCallable('aiProviderExpert').call({'prompt': prompt});
    return res.data['reply'] as String;
  }

  @override
  Stream<List<String>> watchAdminPhones() => _db
      .collection('settings')
      .doc('admins')
      .snapshots()
      .map((d) => List<String>.from(d.data()?['phones'] ?? ['09148002461']));

  @override
  Future<void> addAdminPhone(String phone) =>
      _db.collection('settings').doc('admins').set({
        'phones': FieldValue.arrayUnion([phone]),
      }, SetOptions(merge: true));

  @override
  Future<void> removeAdminPhone(String phone) async {
    if (phone == '09148002461') throw Exception('شمارهٔ مدیر ارشد قابل حذف نیست');
    await _db.collection('settings').doc('admins').set({
      'phones': FieldValue.arrayRemove([phone]),
    }, SetOptions(merge: true));
  }

  @override
  Stream<double> watchCommission() => _db
      .collection('settings')
      .doc('app')
      .snapshots()
      .map((d) => (d.data()?['commissionRate'] ?? 0.15).toDouble());

  @override
  Future<void> setCommission(double v) =>
      _db.collection('settings').doc('app').set({'commissionRate': v}, SetOptions(merge: true));

  /// دستیار هوشمند — Gemini روی Cloud Functions
  @override
  Future<String> askAssistant(String prompt) async {
    final res = await _fn.httpsCallable('aiAssistant').call({'prompt': prompt});
    return res.data['reply'] as String;
  }
}
