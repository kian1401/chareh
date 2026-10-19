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
    // 🔗 حساب متخصص ← پروفایل متخصص (پیوند userId)
    _subProviders = RepoHub.instance.providers.watchAll().listen((ps) {
      _linkedProviderId = ps.where((p) => p.userId != null && p.userId == user?.id).firstOrNull?.id;
      notifyListeners();
    });
  }

  AppUser? user;
  UserRole portal = UserRole.customer;

  /// وقتی فلیور جداگانه (مثلاً اپ متخصص) اجرا شده، تعویض پرتال غیرفعال است
  bool locked = false;

  StreamSubscription<AppUser?>? _sub;

  bool get loggedIn => user != null;
  bool get isAdmin => user?.role == UserRole.admin;

  /// 👀 پیش‌نمایش پنل متخصص از داخل ادمین (impersonation)
  String? _previewProviderId;
  String? _linkedProviderId;
  StreamSubscription<List<ProviderProfile>>? _subProviders;

  String? get linkedProviderId => _linkedProviderId;
  String? get effectiveProviderId => _previewProviderId ?? _linkedProviderId;

  /// آیا ادمین در حال مشاهدهٔ پنل یک متخصص است؟
  bool get isPreviewingProvider => _previewProviderId != null;

  void enterProviderPreview(String providerId) {
    _previewProviderId = providerId;
    notifyListeners();
  }

  void exitProviderPreview() {
    _previewProviderId = null;
    notifyListeners();
  }

  void setPortal(UserRole role) {
    portal = role;
    notifyListeners();
  }

  /// برگشت: کد صادرشده (حالت تست — روی صفحه نمایش داده می‌شود)
  Future<String> sendOtp(String phone) =>
      RepoHub.instance.auth.sendOtp(phone: phone, role: portal);

  Future<AppUser> verifyOtp(String phone, String code, {String? referralCode}) =>
      RepoHub.instance.auth.verifyOtp(phone: phone, code: code, referralCode: referralCode);

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
    _subProviders?.cancel();
    super.dispose();
  }
}
