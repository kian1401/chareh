import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import 'auth_state.dart';

/// صفحه‌ی آغازین: انتخاب پرتال (در نسخه‌ی واقعی با اپ جداگانه/فلیور پیاده می‌شود)
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isMock = RepoHub.instance.isMock;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Text('🏙️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('چاره',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'هر خدمتی، از در خانه‌ی شما\nنظافت • تعمیرات • زیبایی • اسباب‌کشی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .85),
                      fontSize: 14,
                      height: 1.8),
                ),
                const Spacer(),
                _RoleCard(
                  emoji: '🙋‍♀️',
                  title: 'ورود به عنوان مشتری',
                  subtitle: 'رزرو سرویس، پیگیری و پرداخت',
                  onTap: () {
                    auth.setPortal(UserRole.customer);
                    context.go('/c/home');
                  },
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  emoji: '🧑‍🔧',
                  title: 'ورود به عنوان سرویس‌دهنده',
                  subtitle: 'دریافت سفارش، مدیریت کارها و درآمد',
                  onTap: () {
                    auth.setPortal(UserRole.provider);
                    context.go('/p/home');
                  },
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  emoji: '🛡️',
                  title: 'ورود به عنوان مدیر سیستم',
                  subtitle: 'داشبورد، مدیریت سرویس‌ها و کاربران',
                  onTap: () {
                    auth.setPortal(UserRole.admin);
                    context.go('/a/home');
                  },
                ),
                if (isMock) ...[
                  const SizedBox(height: 16),
                  Text(
                    'نسخه‌ی دمو با داده‌ی موک • ورود با هر کد ۶ رقمی',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .7), fontSize: 11.5),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
