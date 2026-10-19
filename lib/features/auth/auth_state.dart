import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';

/// وضعیت سراسری احراز هویت + پرتال فعلی (مشتری/سرویس‌دهنده/ادمین)
class AuthState extends ChangeNotifier {
  AuthState({UserRole? initialPortal}) {
    if (initialPortal != null) {
      portal = initialPortal;
      locked = true;
    }
    _sub = RepoHub.instance.auth.watchUser().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  AppUser? user;
  UserRole portal = UserRole.customer;

  /// وقتی فلیور جداگانه (مثلاً اپ متخصص) اجرا شده، تعویض پرتال غیرفعال است
  bool locked = false;

  StreamSubscription<AppUser?>? _sub;

  bool get loggedIn => user != null;

  /// اتصال دموی کاربر سرویس‌دهنده به پروفایل «حسین اکبری»
  String? get linkedProviderId =>
      (user != null && user!.role == UserRole.provider) ? 'p7' : null;

  void setPortal(UserRole role) {
    portal = role;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) =>
      RepoHub.instance.auth.sendOtp(phone: phone, role: portal);

  Future<AppUser> verifyOtp(String phone, String code) =>
      RepoHub.instance.auth.verifyOtp(phone: phone, code: code);

  Future<AppUser> demoLogin(UserRole role) =>
      RepoHub.instance.auth.signInDemo(role);

  Future<void> signOut() => RepoHub.instance.auth.signOut();

  bool isFavorite(String serviceId) => user?.favorites.contains(serviceId) ?? false;

  Future<void> toggleFavorite(String serviceId) =>
      RepoHub.instance.auth.toggleFavorite(serviceId);

  /// بازخوانی دستی UI (برای تغییرات محلی دمو مثل شارژ کیف پول)
  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
