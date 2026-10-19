import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';

/// وضعیت سراسری احراز هویت + پرتال فعلی + پیش‌نمایش ادمین روی پنل متخصص
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
    // پیوند خودکار حساب متخصص به پروفایل (بر اساس شماره موبایل)
    _subProv = RepoHub.instance.providers.watchAll().listen((list) {
      _myProvider = null;
      final u = user;
      if (u != null && u.role == UserRole.provider) {
        for (final p in list) {
          if (p.phone == u.phone || p.userId == u.id) { _myProvider = p; break; }
        }
      }
      notifyListeners();
    });
  }

  AppUser? user;
  UserRole portal = UserRole.customer;
  bool locked = false;

  /// 🔍 ادمین: واردِ پنل این متخصص شو (پیش‌نمایش)
  String? previewProviderId;

  StreamSubscription<AppUser?>? _sub;
  StreamSubscription<List<ProviderProfile>>? _subProv;
  ProviderProfile? _myProvider;

  bool get loggedIn => user != null;
  bool get isAdmin => user?.role == UserRole.admin;

  /// شناسهٔ متخصصِ کاربر جاری (از روی ثبت شماره خطاطش/admin)
  String? get linkedProviderId => _myProvider?.id;

  /// شناسهٔ متخصصی که در UI پنل واقعی‌اش را می‌بینیم (خودم یا پیش‌نمایش ادمین)
  String? get effectiveProviderId {
    if (previewProviderId != null && portal == UserRole.provider) return previewProviderId;
    return linkedProviderId;
  }

  bool get isPreviewingProvider => previewProviderId != null && previewProviderId != linkedProviderId;

  void enterProviderPreview(String providerId) {
    previewProviderId = providerId;
    portal = UserRole.provider;
    notifyListeners();
  }

  void exitProviderPreview() {
    previewProviderId = null;
    notifyListeners();
  }

  void setPortal(UserRole role) {
    portal = role;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) =>
      RepoHub.instance.auth.sendOtp(phone: phone, role: portal);

  Future<AppUser> verifyOtp(String phone, String code, {String? referralCode}) =>
      RepoHub.instance.auth.verifyOtp(phone: phone, code: code, referralCode: referralCode);

  Future<void> signOut() => RepoHub.instance.auth.signOut();

  bool isFavorite(String serviceId) => user?.favorites.contains(serviceId) ?? false;
  Future<void> toggleFavorite(String serviceId) => RepoHub.instance.auth.toggleFavorite(serviceId);

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub?.cancel();
    _subProv?.cancel();
    super.dispose();
  }
}
