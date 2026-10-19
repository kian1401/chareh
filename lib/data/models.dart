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
  List<String> favorites; // شناسه‌ی سرویس‌ها

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarEmoji = '🙂',
    this.walletBalance = 0,
    List<String>? favorites,
  }) : favorites = favorites ?? [];

  bool get isLoggedIn => id.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'role': role.name,
        'avatarEmoji': avatarEmoji,
        'walletBalance': walletBalance,
        'favorites': favorites,
      };

  factory AppUser.fromJson(String id, Map<String, dynamic> j) => AppUser(
        id: id,
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        role: UserRoleX.fromName(j['role']),
        avatarEmoji: j['avatarEmoji'] ?? '🙂',
        walletBalance: (j['walletBalance'] ?? 0) as int,
        favorites: List<String>.from(j['favorites'] ?? []),
      );
}

// ─────────────────────────── دسته‌بندی ───────────────────────────
class Category {
  final String id;
  String title;
  String emoji;
  bool active;

  Category({required this.id, required this.title, required this.emoji, this.active = true});

  Map<String, dynamic> toJson() => {'title': title, 'emoji': emoji, 'active': active};

  factory Category.fromJson(String id, Map<String, dynamic> j) =>
      Category(id: id, title: j['title'] ?? '', emoji: j['emoji'] ?? '🔧', active: j['active'] ?? true);
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
  int jobsDone;
  bool verified;
  bool online;
  String level; // «حرفه‌ای»، «برتر»...

  ProviderProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.skills,
    this.rating = 4.8,
    this.jobsDone = 0,
    this.verified = true,
    this.online = true,
    this.level = 'حرفه‌ای',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'skills': skills,
        'rating': rating,
        'jobsDone': jobsDone,
        'verified': verified,
        'online': online,
        'level': level,
      };

  factory ProviderProfile.fromJson(String id, Map<String, dynamic> j) => ProviderProfile(
        id: id,
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '🧑‍🔧',
        skills: List<String>.from(j['skills'] ?? []),
        rating: (j['rating'] ?? 0).toDouble(),
        jobsDone: (j['jobsDone'] ?? 0) as int,
        verified: j['verified'] ?? false,
        online: j['online'] ?? true,
        level: j['level'] ?? 'حرفه‌ای',
      );
}

// ─────────────────────────── آدرس ───────────────────────────
class AddressItem {
  final String id;
  final String title; // خانه، محل کار...
  final String text;
  final bool isDefault;

  const AddressItem({
    required this.id,
    required this.title,
    required this.text,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {'title': title, 'text': text, 'isDefault': isDefault};

  factory AddressItem.fromJson(String id, Map<String, dynamic> j) => AddressItem(
        id: id,
        title: j['title'] ?? '',
        text: j['text'] ?? '',
        isDefault: j['isDefault'] ?? false,
      );
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
  String dayLabel;
  String timeSlot;
  String addressText;
  BookingStatus status;
  int totalPrice;
  DateTime createdAt;
  List<StatusEvent> timeline;
  int? rating;
  String? review;
  String paymentMethod; // «آنلاین» یا «کیف پول» یا «نقدی»

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
    required this.dayLabel,
    required this.timeSlot,
    required this.addressText,
    this.status = BookingStatus.pending,
    required this.totalPrice,
    DateTime? createdAt,
    List<StatusEvent>? timeline,
    this.rating,
    this.review,
    this.paymentMethod = 'آنلاین',
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
        'dayLabel': dayLabel,
        'timeSlot': timeSlot,
        'addressText': addressText,
        'status': status.name,
        'totalPrice': totalPrice,
        'createdAt': createdAt.toIso8601String(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'rating': rating,
        'review': review,
        'paymentMethod': paymentMethod,
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
        providerId: j['providerId'],
        providerName: j['providerName'],
        providerEmoji: j['providerEmoji'],
        dayLabel: j['dayLabel'] ?? '',
        timeSlot: j['timeSlot'] ?? '',
        addressText: j['addressText'] ?? '',
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
  DateTime? day;
  String? timeSlot;
  AddressItem? address;
  String paymentMethod = 'آنلاین';

  void reset(ServiceItem s) {
    service = s;
    option = s.options.isNotEmpty ? s.options.first : null;
    addOnIds.clear();
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

  bool get ready => service != null && option != null && day != null && timeSlot != null && address != null;

  String get dayLabel => day == null ? '' : faDayLabel(day!);
}
