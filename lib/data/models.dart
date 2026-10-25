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
enum BookingStatus {
  pending,
  accepted,
  onTheWay,
  inProgress,
  completed,
  rejected,
  cancelled,
}

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
    BookingStatus.accepted => const Color(0xFF2D7DD2),
    BookingStatus.onTheWay => const Color(0xFF7C3AED),
    BookingStatus.inProgress => const Color(0xFF0891B2),
    BookingStatus.completed => const Color(0xFF0E9F6E),
    BookingStatus.rejected ||
    BookingStatus.cancelled => const Color(0xFFE02424),
  };

  bool get isActive => switch (this) {
    BookingStatus.pending ||
    BookingStatus.accepted ||
    BookingStatus.onTheWay ||
    BookingStatus.inProgress => true,
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
  String referralCode; // کد دعوت خود کاربر
  String? referredBy; // کدی که هنگام ثبت‌نام وارد شد
  List<String> favorites; // شناسه‌ی سرویس‌ها

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
/// تصویر بسته‌بندی‌شدهٔ پیش‌فرض هر دستهٔ مادر
const catImageMap = {
  'c_appliance': 'assets/categories/cat_appliance.jpg',
  'c_hvac': 'assets/categories/cat_hvac.jpg',
  'c_elec': 'assets/categories/cat_elec.jpg',
  'c_plumb': 'assets/categories/cat_plumb.jpg',
  'c_paint': 'assets/categories/cat_paint.jpg',
  'c_clean': 'assets/categories/cat_clean.jpg',
};

extension CategoryImageX on Category {
  String get effectiveImage =>
      imageUrl.isNotEmpty ? imageUrl : (catImageMap[id] ?? '');
}

class Category {
  final String id;
  String title;
  String emoji;
  String imageUrl; // لینک ادمین یا asset پیش‌فرض (از effectiveImage)
  int order;
  bool featured;
  bool active;

  Category({
    required this.id,
    required this.title,
    required this.emoji,
    this.imageUrl = '',
    this.order = 99,
    this.featured = false,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'order': order,
    'featured': featured,
    'active': active,
  };

  factory Category.fromJson(String id, Map<String, dynamic> j) => Category(
    id: id,
    title: j['title'] ?? '',
    emoji: j['emoji'] ?? '🔧',
    imageUrl: j['imageUrl'] ?? '',
    order: (j['order'] ?? 99) as int,
    featured: j['featured'] ?? false,
    active: j['active'] ?? true,
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

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'price': price,
    'duration': duration,
  };

  factory ServiceOption.fromJson(String id, Map<String, dynamic> j) =>
      ServiceOption(
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
  String imageUrl;
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

  factory ServiceItem.fromJson(String id, Map<String, dynamic> j) =>
      ServiceItem(
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
            ServiceOption.fromJson(
              'opt$i',
              (j['options'] as List)[i] as Map<String, dynamic>,
            ),
        ],
        addOns: [
          for (var i = 0; i < (j['addOns'] as List? ?? []).length; i++)
            AddOn.fromJson(
              'add$i',
              (j['addOns'] as List)[i] as Map<String, dynamic>,
            ),
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

  Map<String, dynamic> toJson() => {
    'author': author,
    'rating': rating,
    'text': text,
    'dateLabel': dateLabel,
  };

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
  bool active; // مسدود/حذف غیرمستقیم توسط ادمین
  String level; // «حرفه‌ای»، «برتر»...
  String cityId;
  String phone; // واقعی — فقط ادمین/خودش می‌بیند
  String? userId; // پیوند به حساب ورود OTP

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

  factory ProviderProfile.fromJson(String id, Map<String, dynamic> j) =>
      ProviderProfile(
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
  final double lat;
  final double lng;
  final String cityId;
  final String plaque; // پلاک
  final String floor; // طبقه
  final String unit; // شمارهٔ واحد
  final bool isDefault;

  const AddressItem({
    required this.id,
    required this.title,
    required this.text,
    this.lat = 37.55,
    this.lng = 45.07,
    this.cityId = 'urmia',
    this.plaque = '',
    this.floor = '',
    this.unit = '',
    this.isDefault = false,
  });

  /// متن کمل آدرس برای نمایش/رزرو
  String get fullText {
    final parts = <String>[text];
    if (plaque.isNotEmpty) parts.add('پلاک $plaque');
    if (floor.isNotEmpty) parts.add('طبقهٔ $floor');
    if (unit.isNotEmpty) parts.add('واحد $unit');
    return parts.join('، ');
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'text': text,
    'lat': lat,
    'lng': lng,
    'cityId': cityId,
    'plaque': plaque,
    'floor': floor,
    'unit': unit,
    'isDefault': isDefault,
  };

  factory AddressItem.fromJson(String id, Map<String, dynamic> j) =>
      AddressItem(
        id: id,
        title: j['title'] ?? '',
        text: j['text'] ?? '',
        lat: (j['lat'] ?? 37.55).toDouble(),
        lng: (j['lng'] ?? 45.07).toDouble(),
        cityId: j['cityId'] ?? 'urmia',
        plaque: j['plaque'] ?? '',
        floor: j['floor'] ?? '',
        unit: j['unit'] ?? '',
        isDefault: j['isDefault'] ?? false,
      );
}

// ─────────────────────────── شهر ───────────────────────────
class City {
  final String id;
  String title;
  String province;
  bool active;
  int order;

  City({
    required this.id,
    required this.title,
    required this.province,
    this.active = false,
    this.order = 99,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'province': province,
    'active': active,
    'order': order,
  };

  factory City.fromJson(String id, Map<String, dynamic> j) => City(
    id: id,
    title: j['title'] ?? '',
    province: j['province'] ?? '',
    active: j['active'] ?? false,
    order: (j['order'] ?? 99) as int,
  );
}

// ─────────────────────────── سفارش ───────────────────────────
class StatusEvent {
  final BookingStatus status;
  final DateTime at;
  final String? note;

  const StatusEvent(this.status, this.at, {this.note});

  String get label => status.fa;

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'at': at.toIso8601String(),
    if (note != null) 'note': note,
  };

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
  String customerPhone; // واقعی — قبل از پذیرش ماسک می‌شود
  String? providerId;
  String? providerName;
  String? providerEmoji;
  String cityId;
  String dayLabel; // متن نمایشی روز(ها)
  String timeSlot; // متن نمایشی بازه(ها)
  List<String> candidateDays; // روزهای پیشنهادی مشتری
  List<String> candidateSlots; // بازه‌های پیشنهادی مشتری
  String? confirmedDay; // نهایی‌شده توسط سرویس‌دهنده
  String? confirmedSlot;
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
  bool contactRevealed; // پس از پذیرش، تماس باز می‌شود (ضد دورزدن)

  Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceEmoji,
    required this.optionTitle,
    this.addOnTitles = const [],
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.providerId,
    this.providerName,
    this.providerEmoji,
    this.cityId = 'urmia',
    required this.dayLabel,
    required this.timeSlot,
    this.candidateDays = const [],
    this.candidateSlots = const [],
    this.confirmedDay,
    this.confirmedSlot,
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
  }) : createdAt = createdAt ?? DateTime.now(),
       timeline =
           timeline ?? [StatusEvent(BookingStatus.pending, DateTime.now())];

  /// 🔒 شماره مشتری: تا پذیرش متخصص ماسک می‌ماند
  /// [viewerIsProvider] = آیا بیننده متخصص است (فقط او منتظر ماسک است)
  String maskedContact([bool viewerIsProvider = false]) {
    final p = customerPhone;
    if (p.length < 11) return p;
    if (contactRevealed || !viewerIsProvider) return p;
    return '${p.substring(0, 4)}⁎⁎⁎⁎${p.substring(7)}';
  }

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'serviceTitle': serviceTitle,
    'serviceEmoji': serviceEmoji,
    'optionTitle': optionTitle,
    'addOnTitles': addOnTitles,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
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

  factory Booking.fromJson(String id, Map<String, dynamic> j) => Booking(
    id: id,
    serviceId: j['serviceId'] ?? '',
    serviceTitle: j['serviceTitle'] ?? '',
    serviceEmoji: j['serviceEmoji'] ?? '🔧',
    optionTitle: j['optionTitle'] ?? '',
    addOnTitles: List<String>.from(j['addOnTitles'] ?? []),
    customerId: j['customerId'] ?? '',
    customerName: j['customerName'] ?? '',
    customerPhone: j['customerPhone'] ?? '',
    providerId: j['providerId'],
    providerName: j['providerName'],
    providerEmoji: j['providerEmoji'],
    cityId: j['cityId'] ?? 'urmia',
    dayLabel: j['dayLabel'] ?? '',
    timeSlot: j['timeSlot'] ?? '',
    candidateDays: List<String>.from(j['candidateDays'] ?? []),
    candidateSlots: List<String>.from(j['candidateSlots'] ?? []),
    confirmedDay: j['confirmedDay'],
    confirmedSlot: j['confirmedSlot'],
    addressText: j['addressText'] ?? '',
    addressLat: (j['addressLat'] ?? 37.55).toDouble(),
    addressLng: (j['addressLng'] ?? 45.07).toDouble(),
    status: BookingStatusX.fromName(j['status']),
    totalPrice: (j['totalPrice'] ?? 0) as int,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    timeline: [
      for (final e in (j['timeline'] as List? ?? []))
        StatusEvent.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    rating: j['rating'],
    review: j['review'],
    paymentMethod: j['paymentMethod'] ?? 'آنلاین',
    contactRevealed: j['contactRevealed'] ?? false,
  );
}

// ─────────────────── پیش‌نویس رزرو (حالت مشتری) ───────────────────
class BookingDraft {
  ServiceItem? service;
  ServiceOption? option;
  final Set<String> addOnIds = {};
  final List<String> days = []; // چند روز پیشنهادی
  final List<String> slots = []; // چند بازه زمانی
  bool agreementAccepted = false; // 🛡️ توافق عدم دورزدن پلتفرم
  DateTime? day;
  String? timeSlot;
  AddressItem? address;
  String cityId;
  String paymentMethod = 'آنلاین';

  BookingDraft({this.cityId = 'urmia'});

  void reset(ServiceItem s) {
    service = s;
    option = s.options.isNotEmpty ? s.options.first : null;
    addOnIds.clear();
    days.clear();
    slots.clear();
    agreementAccepted = false;
    day = null;
    timeSlot = null;
    address = null;
    paymentMethod = 'آنلاین';
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
      service != null &&
      option != null &&
      days.isNotEmpty &&
      slots.isNotEmpty &&
      address != null;

  String get dayLabel => day == null ? '' : faDayLabel(day!);
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

  Map<String, dynamic> toJson() => {
    'threadId': threadId,
    'isMine': isMine,
    'text': text,
    'at': at.toIso8601String(),
  };

  factory ChatMessage.fromJson(String id, Map<String, dynamic> j) =>
      ChatMessage(
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

  Map<String, dynamic> toJson() => {
    'title': title,
    'dateLabel': dateLabel,
    'amount': amount,
    'settled': settled,
  };

  factory EarningEntry.fromJson(String id, Map<String, dynamic> j) =>
      EarningEntry(
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

  factory AppNotification.fromJson(String id, Map<String, dynamic> j) =>
      AppNotification(
        id: id,
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        emoji: j['emoji'] ?? '🔔',
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
        unread: j['unread'] ?? true,
      );
}

// ─────────────────── کیف پول ───────────────────
class WalletTxn {
  final String id;
  final String userId;
  final String title;
  final int amount; // مثبت شارژ/هدیه، منفی هزینه
  final bool isBonus;
  final DateTime at;

  const WalletTxn({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.isBonus = false,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'title': title,
    'amount': amount,
    'isBonus': isBonus,
    'at': at.toIso8601String(),
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

/// 🎁 پلهٔ بونس شارژ کیف پول (ادیت‌پذیر از پنل ادمین)
class WalletBonusTier {
  String id;
  int minAmount; // حداقل شارژ (تومان)
  int bonusPercent; // درصد هدیه

  WalletBonusTier({
    this.id = '',
    required this.minAmount,
    required this.bonusPercent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'minAmount': minAmount,
    'bonusPercent': bonusPercent,
  };

  factory WalletBonusTier.fromJson(Map<String, dynamic> j) => WalletBonusTier(
    id: j['id'] ?? '',
    minAmount: (j['minAmount'] ?? 0) as int,
    bonusPercent: (j['bonusPercent'] ?? 0) as int,
  );
}

/// ⚙️ تنظیمات CMS که ادمین زنده تغییر می‌دهد
class AppSettings {
  String appTitle;
  String logoEmoji;
  String primaryHex; // رنگ اصلی برند (ادیت‌پذیر)
  String fontFamily;
  String heroImageUrl; // تصویر هیرو (لینک ادمین)
  String geminiApiKey; // 🔑 برای کارشناس AI متخصص
  String defaultCityId;
  List<WalletBonusTier> bonusTiers;
  int referralReward; // جایزهٔ دعوت (تومان)
  double commissionRate; // کمیسیون پلتفرم
  String telegramUrl;
  String instagramUrl;
  String whatsappUrl;
  bool socialOrderComingSoon; // سفارش از شبکه‌ها «به‌زودی»

  AppSettings({
    this.appTitle = 'چاره',
    this.logoEmoji = '🧡',
    this.primaryHex = '#E85C24',
    this.fontFamily = 'Vazirmatn',
    this.heroImageUrl = '',
    this.geminiApiKey = '',
    this.defaultCityId = 'urmia',
    List<WalletBonusTier>? bonusTiers,
    this.referralReward = 50000,
    this.commissionRate = 0.12,
    this.telegramUrl = '',
    this.instagramUrl = '',
    this.whatsappUrl = '',
    this.socialOrderComingSoon = true,
  }) : bonusTiers =
           bonusTiers ??
           [
             WalletBonusTier(minAmount: 100000, bonusPercent: 5),
             WalletBonusTier(minAmount: 300000, bonusPercent: 10),
             WalletBonusTier(minAmount: 500000, bonusPercent: 15),
           ];

  Map<String, dynamic> toJson() => {
    'appTitle': appTitle,
    'logoEmoji': logoEmoji,
    'primaryHex': primaryHex,
    'fontFamily': fontFamily,
    'heroImageUrl': heroImageUrl,
    'geminiApiKey': geminiApiKey,
    'defaultCityId': defaultCityId,
    'bonusTiers': bonusTiers.map((e) => e.toJson()).toList(),
    'referralReward': referralReward,
    'commissionRate': commissionRate,
    'telegramUrl': telegramUrl,
    'instagramUrl': instagramUrl,
    'whatsappUrl': whatsappUrl,
    'socialOrderComingSoon': socialOrderComingSoon,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    appTitle: j['appTitle'] ?? 'چاره',
    logoEmoji: j['logoEmoji'] ?? '🧡',
    primaryHex: j['primaryHex'] ?? '#E85C24',
    fontFamily: j['fontFamily'] ?? 'Vazirmatn',
    heroImageUrl: j['heroImageUrl'] ?? '',
    geminiApiKey: j['geminiApiKey'] ?? '',
    defaultCityId: j['defaultCityId'] ?? 'urmia',
    bonusTiers: [
      for (final e in (j['bonusTiers'] as List? ?? []))
        WalletBonusTier.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    referralReward: (j['referralReward'] ?? 50000) as int,
    commissionRate: (j['commissionRate'] ?? 0.12).toDouble(),
    telegramUrl: j['telegramUrl'] ?? '',
    instagramUrl: j['instagramUrl'] ?? '',
    whatsappUrl: j['whatsappUrl'] ?? '',
    socialOrderComingSoon: j['socialOrderComingSoon'] ?? true,
  );
}
