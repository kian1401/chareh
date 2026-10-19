import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import 'auth_state.dart';

/// ورود با شماره موبایل + OTP
/// دمو: هر کد ۶ رقمی پذیرفته می‌شود — در حالت Firebase با Cloud Functions (sendOtp/verifyOtp) کار می‌کند.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid =>
      _phoneCtrl.text.length == 11 && _phoneCtrl.text.startsWith('09');

  String get _phone => _phoneCtrl.text.trim();

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().sendOtp(_phone);
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = 'خطا در ارسال کد؛ دوباره تلاش کنید');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthState>().verifyOtp(_phone, _otpCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خوش آمدید! 🎉')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'کد باید ۶ رقم باشد');
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
            const Text('📱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _otpSent ? 'کد تایید را وارد کنید' : 'با شماره موبایل وارد شوید',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'کد ۶ رقمی به شماره‌ی ${toFaDigits(_phone)} پیامک شد'
                  : 'ورود به پرتال «${portal.fa}» — برای ادامه شماره موبایل خود را وارد کنید',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtext, fontSize: 13, height: 1.8),
            ),
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
                  hintText: '۰۹۱۲۴۵۶۷۸۹۰',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                onChanged: (_) => setState(() {}),
              )
            else
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
                  if (v.length == 6) _verify();
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : (_otpSent ? (_otpCtrl.text.length == 6 ? _verify : null) : (_phoneValid ? _sendOtp : null)),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_otpSent ? 'تایید و ورود' : 'ارسال کد تایید'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                  _otpCtrl.clear();
                }),
                child: const Text('ویرایش شماره موبایل'),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💡 نسخه‌ی دمو: هر کد ۶ رقمی (مثلاً ۱۲۳۴۵۶) پذیرفته می‌شود.',
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
