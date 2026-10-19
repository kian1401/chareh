import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import 'auth_state.dart';

String _toEnDigits(String v) {
  const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in v.characters) {
    var i = fa.indexOf(ch);
    if (i >= 0) { b.write(i); continue; }
    i = ar.indexOf(ch);
    b.write(i >= 0 ? i : ch);
  }
  return b.toString();
}

/// ورود با شماره موبایل + OTP
/// 🧪 حالت تست: چون هنوز SMS وصل نیست، کد ۶ رقمی روی همین صفحه نمایش داده می‌شود.
/// 🔐 پنل مدیریت فقط برای شمارهٔ ارشد (۰۹۱۴۸۰۰۲۴۶۱) و مدیران ثبت‌شدهٔ توسط او باز می‌شود.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  bool _showRef = false;
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  String _devCode = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  String get _phone => _toEnDigits(_phoneCtrl.text.trim());
  bool get _phoneValid => _phone.length == 11 && _phone.startsWith('09');
  String get _otp => _toEnDigits(_otpCtrl.text.trim());

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await context.read<AuthState>().sendOtp(_phone);
      setState(() {
        _otpSent = true;
        _devCode = code;
        _otpCtrl.text = code; // پرکردن خودکار — کاربر فقط «تایید و ورود» را می‌زند
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().verifyOtp(
            _phone,
            _otp,
            referralCode: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خوش آمدید! 🎉')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<AuthState>().portal;

    return Scaffold(
      appBar: AppBar(title: const Text('ورود / ثبت‌نام')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(portal == UserRole.admin ? '🛡️' : portal == UserRole.provider ? '🧑‍🔧' : '📱',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _otpSent ? 'کد تایید را وارد کنید' : 'با شماره موبایل وارد شوید',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'کد ۶ رقمی برای ${toFaDigits(_phone)} صادر شد'
                  : 'ورود به پرتال «${portal.fa}» — برای ادامه شماره موبایل خود را وارد کنید',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtext, fontSize: 13, height: 1.8),
            ),
            if (portal == UserRole.admin && !_otpSent) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: .35)),
                ),
                child: const Text(
                  '🔒 ورود به پنل مدیریت محدود است: فقط شمارهٔ ارشد «۰۹۱۴۸۰۰۲۴۶۱» یا شماره‌هایی که او در تب کاربران ثبت کرده کد دریافت می‌کنند.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.8, color: AppColors.text),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!_otpSent)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                decoration: const InputDecoration(
                  hintText: '09148002461',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            if (!_otpSent) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => setState(() => _showRef = !_showRef),
                icon: Icon(_showRef ? Icons.remove_red_eye_outlined : Icons.card_giftcard_rounded, size: 18),
                label: Text(_showRef ? 'کد دعوت ثبت می‌شود' : 'کد دعوت دارم 🎁'),
              ),
              if (_showRef)
                TextField(
                  controller: _refCtrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 3),
                  decoration: const InputDecoration(
                    hintText: 'CHR۱۲۳۴',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'هر شماره = یک حساب دائمی واقعی 👤 (بدون حساب‌های نمایشی)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.subtext, height: 1.7),
              ),
            ] else ...[
              // 🧪 کارت نمایش کد — چون SMS فعال نیست، کد را همین‌جا می‌بینی
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: .12),
                    AppColors.accent.withValues(alpha: .1),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
                ),
                child: Column(children: [
                  const Text('🧪 حالت تست — کد تأیید شما:',
                      style: TextStyle(fontSize: 12.5, color: AppColors.subtext)),
                  const SizedBox(height: 6),
                  Text(toFaDigits(_devCode).split('').join(' '),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 6,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  const Text('به‌صورت خودکار وارد شد؛ فقط «تایید و ورود» را بزنید ✅',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.subtext, height: 1.6)),
                ]),
              ),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                ),
                onChanged: (v) {
                  setState(() {});
                  if (_otp.length == 6) _verify();
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12.5, height: 1.7)),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : (_otpSent ? (_otp.length == 6 ? _verify : null) : (_phoneValid ? _sendOtp : null)),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_otpSent ? 'تایید و ورود' : 'ارسال کد تایید'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _otpSent = false;
                            _otpCtrl.clear();
                            _devCode = '';
                          }),
                  child: const Text('ویرایش شماره'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _sendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('ارسال مجدد کد'),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '📩 نسخه آلفا: SMS به‌زودی با کاوه‌نگار/قاصدک وصل می‌شود — تا آن زمان کد تأیید روی همین صفحه نمایش داده می‌شود.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
