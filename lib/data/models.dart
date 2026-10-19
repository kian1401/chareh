/// مدل‌های دامنه‌ی «چاره»
/// همه‌ی مدل‌ها toJson/fromJson دارند تا بدون تغییر روی Firestore هم کار کنند.
library;

import 'package:flutter/material.dart';
import '../core/utils/persian_utils.dart';

// ───────────────────────────── نقش‌ها ─────────────────────────────
enum UserRole { customer, provider, admin }

extension UserRoleX on UserRole {
  String get fa => switch (this) {
        UserRole.customer => 'مشتری',
        UserRole.provider => 'سرویس‌دهنده',
        UserRole.admin => 'مدیر سیستم',
      };

  static UserRole fromName(String? v) => UserRole.values.firstWhere(
        (e) => e.name == v,
        orElse: () => UserRole.customer,
      );
}

// ─────────────────────── وضعیت سفارش ───────────────────────
enum BookingStatus { pending, accepted, onTheWay, inProgress, completed, rejected, cancelled }

extension BookingStatusX on BookingStatus {
  String get fa => switch (this) {
        BookingStatus.pending => 'در انتظار پذیرش',
        BookingStatus.accepted => 'پذیرفته شد',
        BookingStatus.onTheWay => 'در راه است',
        BookingStatus.inProgress => 'در حال انجام',
        BookingStatus.completed => 'تکمیل شد',
        BookingStatus.rejected => 'رد شده',
        BookingStatus.cancelled => 'لغو شده',
      };

  Color get color => switch (this) {
        BookingStatus.pending => const Color(0xFFD97706),
        BookingStatus.accepted => const Color(0xFF2563EB),
        BookingStatus.onTheWay => const Color(0xFF7C3AED),
        BookingStatus.inProgress => const Color(0xFF0891B2),
        BookingStatus.completed => const Color(0xFF059669),
        BookingStatus.rejected || BookingStatus.cancelled => const Color(0xFFDC2626),
      };

  bool get isActive => switch (this) {
        BookingStatus.pending ||
        BookingStatus.accepted ||
        BookingStatus.onTheWay ||
        BookingStatus.inProgress =>
          true,
        _ => false,
      };

  /// گام بعدی برای سرویس‌دهنده (null یعنی پایان مسیر)
  BookingStatus? get next => switch (this) {
        BookingStatus.accepted => BookingStatus.onTheWay,
        BookingStatus.onTheWay => BookingStatus.inProgress,
        BookingStatus.inProgress => BookingStatus.completed,
        _ => null,
      };

  static BookingStatus fromName(String? v) => BookingStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => BookingStatus.pending,
      );
}

// ───────────────────────────── کاربر ─────────────────────────────
class AppUser {
  final String id;
  String name;
  String phone;
  UserRole role;
  String avatarEmoji;
  int walletBalance;
  int points; // امتیاز وفاداری
  String referralCode; // کد دعوت من
  String? referredBy; // اگر با کد دعوت ثبت‌نام کرد
  List<String> favorites;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarEmoji = '🙂',
    this.walletBalance = 0,
    this.points = 0,
    this.referralCode = '',
    this.referredBy,
    List<String>? favorites,
  }) : favorites = favorites ?? [];

  bool get isLoggedIn => id.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'role': role.name,
        'avatarEmoji': avatarEmoji,
        'walletBalance': walletBalance,
        'points': points,
        'referralCode': referralCode,
        'referredBy': referredBy,
        'favorites': favorites,
      };

  factory AppUser.fromJson(String id, Map<String, dynamic> j) => AppUser(
        id: id,
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        role: UserRoleX.fromName(j['role']),
        avatarEmoji: j['avatarEmoji'] ?? '🙂',
        walletBalance: (j['walletBalance'] ?? 0) as int,
        points: (j['points'] ?? 0) as int,
        referralCode: j['referralCode'] ?? '',
        referredBy: j['referredBy'],
        favorites: List<String>.from(j['favorites'] ?? []),
      );
}

// ─────────────────────────── دسته‌بندی ───────────────────────────
class Category {
  final String id;
  String title;
  String emoji;
  String imageUrl; // 👈 تصویر اختصاصی به‌جای اموجی (اختیاری)
  bool active;
  bool featured; // نمایش ویژه در خانه
  int order;

  Category({
    required this.id,
    required this.title,
    required this.emoji,
    this.imageUrl = '',
    this.active = true,
    this.featured = false,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'title': title, 'emoji': emoji, 'imageUrl': imageUrl,
        'active': active, 'featured': featured, 'order': order,
      };

  factory Category.fromJson(String id, Map<String, dynamic> j) => Category(
        id: id, title: j['title'] ?? '', emoji: j['emoji'] ?? '🔧',
        imageUrl: j['imageUrl'] ?? '', active: j['active'] ?? true,
        featured: j['featured'] ?? false, order: (j['order'] ?? 0) as int,
      );
}

// ─────────────────────── سرویس و گزینه‌ها ───────────────────────
class ServiceOption {
  final String id;
  final String title;
  final String subtitle;
  final int price; // تومان
  final String duration; // مثلا «۴ ساعت»

  const ServiceOption({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.price,
    this.duration = '',
  });

  Map<String, dynamic> toJson() =>
      {'title': title, 'subtitle': subtitle, 'price': price, 'duration': duration};

  factory ServiceOption.fromJson(String id, Map<String, dynamic> j) => ServiceOption(
        id: id,
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        price: (j['price'] ?? 0) as int,
        duration: j['duration'] ?? '',
      );
}

class AddOn {
  final String id;
  final String title;
  final int price;

  const AddOn({required this.id, required this.title, required this.price});

  Map<String, dynamic> toJson() => {'title': title, 'price': price};

  factory AddOn.fromJson(String id, Map<String, dynamic> j) =>
      AddOn(id: id, title: j['title'] ?? '', price: (j['price'] ?? 0) as int);
}

class ServiceItem {
  final String id;
  String categoryId;
  String title;
  String description;
  String emoji;
  String imageUrl; // 👈 تصویر اختصاصی (اختیاری)
  int basePrice; // «شروع قیمت از»
  double rating;
  int ratingCount;
  int jobsDone;
  bool active;
  List<ServiceOption> options;
  List<AddOn> addOns;
  List<String> tags;

  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.basePrice,
    this.imageUrl = '',
    this.rating = 4.7,
    this.ratingCount = 0,
    this.jobsDone = 0,
    this.active = true,
    this.options = const [],
    this.addOns = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'emoji': emoji,
        'imageUrl': imageUrl,
        'basePrice': basePrice,
        'rating': rating,
        'ratingCount': ratingCount,
        'jobsDone': jobsDone,
        'active': active,
        'options': options.map((e) => e.toJson()).toList(),
        'addOns': addOns.map((e) => e.toJson()).toList(),
        'tags': tags,
      };

  factory ServiceItem.fromJson(String id, Map<String, dynamic> j) => ServiceItem(
        id: id,
        categoryId: j['categoryId'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        emoji: j['emoji'] ?? '🔧',
        imageUrl: j['imageUrl'] ?? '',
        basePrice: (j['basePrice'] ?? 0) as int,
        rating: (j['rating'] ?? 0).toDouble(),
        ratingCount: (j['ratingCount'] ?? 0) as int,
        jobsDone: (j['jobsDone'] ?? 0) as int,
        active: j['active'] ?? true,
        options: [
          for (var i = 0; i < (j['options'] as List? ?? []).length; i++)
            ServiceOption.fromJson('opt$i', (j['options'] as List)[i] as Map<String, dynamic>)
        ],
        addOns: [
          for (var i = 0; i < (j['addOns'] as List? ?? []).length; i++)
            AddOn.fromJson('add$i', (j['addOns'] as List)[i] as Map<String, dynamic>)
        ],
        tags: List<String>.from(j['tags'] ?? []),
      );
}

class Review {
  final String id;
  final String author;
  final double rating;
  final String text;
  final String dateLabel;

  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.text,
    required this.dateLabel,
  });

  Map<String, dynamic> toJson() =>
      {'author': author, 'rating': rating, 'text': text, 'dateLabel': dateLabel};

  factory Review.fromJson(String id, Map<String, dynamic> j) => Review(
        id: id,
        author: j['author'] ?? '',
        rating: (j['rating'] ?? 5).toDouble(),
        text: j['text'] ?? '',
        dateLabel: j['dateLabel'] ?? '',
      );
}

// ───────────────────────── سرویس‌دهنده ─────────────────────────
class ProviderProfile {
  final String id;
  String name;
  String emoji;
  List<String> skills; // عناوین سرویس‌ها
  double rating;
  int ratingCount;
  int jobsDone;
  bool verified;
  bool online;
  bool active; // حذف/مسدود غیرمستقیم توسط ادمین
  String level; // «حرفه‌ای»، «برتر»...
  String cityId;
  String phone; // واقعی — فقط ادمین/خودش می‌بیند
  String? userId; // پیوند به حساب ورود

  ProviderProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.skills,
    this.rating = 4.8,
    this.ratingCount = 0,
    this.jobsDone = 0,
    this.verified = true,
    this.online = true,
    this.active = true,
    this.level = 'حرفه‌ای',
    this.cityId = 'urmia',
    this.phone = '',
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'skills': skills,
        'rating': rating,
        'ratingCount': ratingCount,
        'jobsDone': jobsDone,
        'verified': verified,
        'online': online,
        'active': active,
        'level': level,
        'cityId': cityId,
        'phone': phone,
        'userId': userId,
      };

  factory ProviderProfile.fromJson(String id, Map<String, dynamic> j) => ProviderProfile(
        id: id,
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '🧑‍🔧',
        skills: List<String>.from(j['skills'] ?? []),
        rating: (j['rating'] ?? 0).toDouble(),
        ratingCount: (j['ratingCount'] ?? 0) as int,
        jobsDone: (j['jobsDone'] ?? 0) as int,
        verified: j['verified'] ?? false,
        online: j['online'] ?? true,
        active: j['active'] ?? true,
        level: j['level'] ?? 'حرفه‌ای',
        cityId: j['cityId'] ?? 'urmia',
        phone: j['phone'] ?? '',
        userId: j['userId'],
      );
}

// ─────────────────────────── آدرس ───────────────────────────
class AddressItem {
  final String id;
  final String title; // خانه، محل کار...
  final String text;
  final bool isDefault;
  final double lat;
  final double lng;
  final String cityId;
  final String plaque; // پلاک/واحد

  const AddressItem({
    required this.id,
    required this.title,
    required this.text,
    this.isDefault = false,
    this.lat = 37.55,
    this.lng = 45.07,
    this.cityId = 'urmia',
    this.plaque = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title, 'text': text, 'isDefault': isDefault,
        'lat': lat, 'lng': lng, 'cityId': cityId, 'plaque': plaque,
      };

  factory AddressItem.fromJson(String id, Map<String, dynamic> j) => AddressItem(
        id: id,
        title: j['title'] ?? '',
        text: j['text'] ?? '',
        isDefault: j['isDefault'] ?? false,
        lat: (j['lat'] ?? 37.55).toDouble(),
        lng: (j['lng'] ?? 45.07).toDouble(),
        cityId: j['cityId'] ?? 'urmia',
        plaque: j['plaque'] ?? '',
      );
}

// ─────────────────────────── شهر فعال / غیرفعال ───────────────────────────
class City {
  final String id;
  String title;
  String province;
  bool active;

  City({required this.id, required this.title, this.province = '', this.active = false});

  Map<String, dynamic> toJson() => {'title': title, 'province': province, 'active': active};

  factory City.fromJson(String id, Map<String, dynamic> j) =>
      City(id: id, title: j['title'] ?? '', province: j['province'] ?? '', active: j['active'] ?? false);
}

// ─────────────────────────── سفارش ───────────────────────────
class StatusEvent {
  final BookingStatus status;
  final DateTime at;
  final String? note;

  const StatusEvent(this.status, this.at, {this.note});

  String get label => status.fa;

  Map<String, dynamic> toJson() =>
      {'status': status.name, 'at': at.toIso8601String(), if (note != null) 'note': note};

  factory StatusEvent.fromJson(Map<String, dynamic> j) => StatusEvent(
        BookingStatusX.fromName(j['status']),
        DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
        note: j['note'],
      );
}

class Booking {
  final String id;
  String serviceId;
  String serviceTitle;
  String serviceEmoji;
  String optionTitle;
  List<String> addOnTitles;
  String customerId;
  String customerName;
  String? providerId;
  String? providerName;
  String? providerEmoji;
  String cityId;
  String dayLabel;          // قدیمی — اگر تک‌روز بود
  String timeSlot;          // قدیمی
  List<String> candidateDays;  // 👈 بازه زمانی چندانتخابی: چند روز
  List<String> candidateSlots; // 👈 چند بازهٔ ساعتی
  String confirmedDay;    // انتخاب نهایی متخصص هنگام پذیرش
  String confirmedSlot;
  String addressText;
  double addressLat;
  double addressLng;
  BookingStatus status;
  int totalPrice;
  DateTime createdAt;
  List<StatusEvent> timeline;
  int? rating;
  String? review;
  String paymentMethod; // «آنلاین» یا «کیف پول» یا «نقدی»
  bool contactRevealed; // عدم دور زدن: تماس واقعی بعد از پذیرش/تکمیل

  Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceEmoji,
    required this.optionTitle,
    this.addOnTitles = const [],
    required this.customerId,
    required this.customerName,
    this.providerId,
    this.providerName,
    this.providerEmoji,
    this.cityId = 'urmia',
    required this.dayLabel,
    required this.timeSlot,
    this.candidateDays = const [],
    this.candidateSlots = const [],
    this.confirmedDay = '',
    this.confirmedSlot = '',
    required this.addressText,
    this.addressLat = 37.55,
    this.addressLng = 45.07,
    this.status = BookingStatus.pending,
    required this.totalPrice,
    DateTime? createdAt,
    List<StatusEvent>? timeline,
    this.rating,
    this.review,
    this.paymentMethod = 'آنلاین',
    this.contactRevealed = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        timeline = timeline ?? [StatusEvent(BookingStatus.pending, DateTime.now())];

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'serviceEmoji': serviceEmoji,
        'optionTitle': optionTitle,
        'addOnTitles': addOnTitles,
        'customerId': customerId,
        'customerName': customerName,
        'providerId': providerId,
        'providerName': providerName,
        'providerEmoji': providerEmoji,
        'cityId': cityId,
        'dayLabel': dayLabel,
        'timeSlot': timeSlot,
        'candidateDays': candidateDays,
        'candidateSlots': candidateSlots,
        'confirmedDay': confirmedDay,
        'confirmedSlot': confirmedSlot,
        'addressText': addressText,
        'addressLat': addressLat,
        'addressLng': addressLng,
        'status': status.name,
        'totalPrice': totalPrice,
        'createdAt': createdAt.toIso8601String(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'rating': rating,
        'review': review,
        'paymentMethod': paymentMethod,
        'contactRevealed': contactRevealed,
      };

  /// شمارهٔ ماسک‌شده (ضد دور زدن پلتفرم)
  String maskedContact(bool isProvider) {
    if (contactRevealed || status == BookingStatus.completed) return '📞 تماس آزاد است';
    return isProvider ? '📞 ۰۹* **** **** — بعد از پذیرش قابل نمایش' : '📞 پل تلفنی امن چاره';
  }

  factory Booking.fromJson(String id, Map<String, dynamic> j) => Booking(
        id: id,
        serviceId: j['serviceId'] ?? '',
        serviceTitle: j['serviceTitle'] ?? '',
        serviceEmoji: j['serviceEmoji'] ?? '🔧',
        optionTitle: j['optionTitle'] ?? '',
        addOnTitles: List<String>.from(j['addOnTitles'] ?? []),
        customerId: j['customerId'] ?? '',
        customerName: j['customerName'] ?? '',
        providerId: j['providerId'],
        providerName: j['providerName'],
        providerEmoji: j['providerEmoji'],
        cityId: j['cityId'] ?? 'urmia',
        dayLabel: j['dayLabel'] ?? '',
        timeSlot: j['timeSlot'] ?? '',
        candidateDays: List<String>.from(j['candidateDays'] ?? []),
        candidateSlots: List<String>.from(j['candidateSlots'] ?? []),
        confirmedDay: j['confirmedDay'] ?? '',
        confirmedSlot: j['confirmedSlot'] ?? '',
        addressText: j['addressText'] ?? '',
        addressLat: (j['addressLat'] ?? 37.55).toDouble(),
        addressLng: (j['addressLng'] ?? 45.07).toDouble(),
        status: BookingStatusX.fromName(j['status']),
        totalPrice: (j['totalPrice'] ?? 0) as int,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        timeline: [
          for (final e in (j['timeline'] as List? ?? []))
            StatusEvent.fromJson(Map<String, dynamic>.from(e as Map))
        ],
        rating: j['rating'],
        review: j['review'],
        paymentMethod: j['paymentMethod'] ?? 'آنلاین',
        contactRevealed: j['contactRevealed'] ?? false,
      );
}

// ─────────────────────────── چت ───────────────────────────
class ChatMessage {
  final String id;
  final String threadId;
  final bool isMine;
  final String text;
  final DateTime at;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.isMine,
    required this.text,
    required this.at,
  });

  Map<String, dynamic> toJson() =>
      {'threadId': threadId, 'isMine': isMine, 'text': text, 'at': at.toIso8601String()};

  factory ChatMessage.fromJson(String id, Map<String, dynamic> j) => ChatMessage(
        id: id,
        threadId: j['threadId'] ?? '',
        isMine: j['isMine'] ?? false,
        text: j['text'] ?? '',
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
      );
}

// ─────────────────────── درآمد سرویس‌دهنده ───────────────────────
class EarningEntry {
  final String id;
  final String title;
  final String dateLabel;
  final int amount;
  final bool settled;

  const EarningEntry({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.amount,
    this.settled = false,
  });

  Map<String, dynamic> toJson() =>
      {'title': title, 'dateLabel': dateLabel, 'amount': amount, 'settled': settled};

  factory EarningEntry.fromJson(String id, Map<String, dynamic> j) => EarningEntry(
        id: id,
        title: j['title'] ?? '',
        dateLabel: j['dateLabel'] ?? '',
        amount: (j['amount'] ?? 0) as int,
        settled: j['settled'] ?? false,
      );
}

// ─────────────────────────── اعلان ───────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String emoji;
  bool unread;
  DateTime at;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.at,
    this.unread = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'emoji': emoji,
        'unread': unread,
        'at': at.toIso8601String(),
      };

  factory AppNotification.fromJson(String id, Map<String, dynamic> j) => AppNotification(
        id: id,
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        emoji: j['emoji'] ?? '🔔',
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
        unread: j['unread'] ?? true,
      );
}

// ─────────────────── پیش‌نویس رزرو (حالت مشتری) ───────────────────
class BookingDraft {
  ServiceItem? service;
  ServiceOption? option;
  final Set<String> addOnIds = {};
  final Set<String> days = {};      // 👈 چند روز قابل انتخاب
  final Set<String> slots = {};     // 👈 چند بازهٔ ساعتی
  AddressItem? address;
  String cityId = 'urmia';
  String paymentMethod = 'آنلاین';
  bool agreementAccepted = false;   // تعهد عدم دور زدن

  void reset(ServiceItem s) {
    service = s;
    option = s.options.isNotEmpty ? s.options.first : null;
    addOnIds.clear();
    days.clear();
    slots.clear();
    address = null;
    paymentMethod = 'آنلاین';
    agreementAccepted = false;
  }

  int get total {
    if (option == null) return 0;
    var t = option!.price;
    for (final a in service!.addOns) {
      if (addOnIds.contains(a.id)) t += a.price;
    }
    return t;
  }

  bool get ready =>
      service != null && option != null && days.isNotEmpty && slots.isNotEmpty && address != null && agreementAccepted;

  String get dayLabel => days.isEmpty ? '' : days.first;
  String get slotLabel => slots.isEmpty ? '' : slots.first;
}

// ─────────────────── تنظیمات سیستم (ادمین/CMS) ───────────────────
class WalletBonusTier {
  final String id;
  int minAmount; // تومان
  int bonusPercent;

  WalletBonusTier({required this.id, required this.minAmount, required this.bonusPercent});

  Map<String, dynamic> toJson() => {'minAmount': minAmount, 'bonusPercent': bonusPercent};
  factory WalletBonusTier.fromJson(String id, Map<String, dynamic> j) =>
      WalletBonusTier(id: id, minAmount: (j['minAmount'] ?? 0) as int, bonusPercent: (j['bonusPercent'] ?? 0) as int);
}

class WalletTxn {
  final String id;
  final String userId;
  final String title;
  final int amount; // +شارژ/بونس  −پرداخت
  final bool isBonus;
  final DateTime at;

  const WalletTxn({required this.id, required this.userId, required this.title,
      required this.amount, this.isBonus = false, required this.at});

  Map<String, dynamic> toJson() => {
        'userId': userId, 'title': title, 'amount': amount,
        'isBonus': isBonus, 'at': at.toIso8601String(),
      };

  factory WalletTxn.fromJson(String id, Map<String, dynamic> j) => WalletTxn(
        id: id,
        userId: j['userId'] ?? '',
        title: j['title'] ?? '',
        amount: (j['amount'] ?? 0) as int,
        isBonus: j['isBonus'] ?? false,
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
      );
}

class AppSettings {
  // 🎨 تم و برند (سطح CMS برای ادمین)
  String appTitle;
  String primaryHex;
  String fontFamily; // weight یکسان — گزینه: وزیرمتن
  String heroImageUrl;
  String logoEmoji;
  // 🤖 هوش مصنوعی متخصص
  String geminiApiKey;
  // 🏙️ شهرها
  String defaultCityId;
  // 💰 کیف پول و تشویق
  List<WalletBonusTier> bonusTiers;
  int referralReward; // پاداش دعوت موفق (تومان)
  double commissionRate;
  // 📱 شبکه‌های اجتماعی
  String telegramUrl, instagramUrl, whatsappUrl;
  bool socialOrderComingSoon;

  AppSettings({
    this.appTitle = 'چاره',
    this.primaryHex = '#6D28D9',
    this.fontFamily = 'Vazirmatn',
    this.heroImageUrl = '',
    this.logoEmoji = '🧩',
    this.geminiApiKey = '',
    this.defaultCityId = 'urmia',
    List<WalletBonusTier>? bonusTiers,
    this.referralReward = 25000,
    this.commissionRate = 0.15,
    this.telegramUrl = '',
    this.instagramUrl = '',
    this.whatsappUrl = '',
    this.socialOrderComingSoon = true,
  }) : bonusTiers = bonusTiers ??
            [WalletBonusTier(id: 't1', minAmount: 100000, bonusPercent: 7),
             WalletBonusTier(id: 't2', minAmount: 300000, bonusPercent: 12),
             WalletBonusTier(id: 't3', minAmount: 500000, bonusPercent: 15)];

  Map<String, dynamic> toJson() => {
        'appTitle': appTitle, 'primaryHex': primaryHex, 'fontFamily': fontFamily,
        'heroImageUrl': heroImageUrl, 'logoEmoji': logoEmoji, 'geminiApiKey': geminiApiKey,
        'defaultCityId': defaultCityId, 'bonusTiers': bonusTiers.map((e) => e.toJson()).toList(),
        'referralReward': referralReward, 'commissionRate': commissionRate,
        'telegramUrl': telegramUrl, 'instagramUrl': instagramUrl, 'whatsappUrl': whatsappUrl,
        'socialOrderComingSoon': socialOrderComingSoon,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        appTitle: j['appTitle'] ?? 'چاره',
        primaryHex: j['primaryHex'] ?? '#6D28D9',
        fontFamily: j['fontFamily'] ?? 'Vazirmatn',
        heroImageUrl: j['heroImageUrl'] ?? '',
        logoEmoji: j['logoEmoji'] ?? '🧩',
        geminiApiKey: j['geminiApiKey'] ?? '',
        defaultCityId: j['defaultCityId'] ?? 'urmia',
        bonusTiers: [
          for (var i = 0; i < (j['bonusTiers'] as List? ?? []).length; i++)
            WalletBonusTier.fromJson('t$i', (j['bonusTiers'] as List)[i] as Map<String, dynamic>)
        ],
        referralReward: (j['referralReward'] ?? 25000) as int,
        commissionRate: (j['commissionRate'] ?? 0.15).toDouble(),
        telegramUrl: j['telegramUrl'] ?? '',
        instagramUrl: j['instagramUrl'] ?? '',
        whatsappUrl: j['whatsappUrl'] ?? '',
        socialOrderComingSoon: j['socialOrderComingSoon'] ?? true,
      );
}

/// بازه‌های ساعتی استاندارد چاره
const charehTimeSlots = ['صبح ۹ تا ۱۲', 'ظهر ۱۲ تا ۱۵', 'عصر ۱۵ تا ۱۸', 'شب ۱۸ تا ۲۱'];
