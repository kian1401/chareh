import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// داشبورد سرویس‌دهنده
class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;
    final auth = context.watch<AuthState>();

    if (auth.effectiveProviderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('داشبورد متخصص')),
        body: const NeedLogin(
          emoji: '🧑‍🔧',
          title: 'حساب متخصص لازم است',
          hint: 'اگر به‌تازگی با شماره‌ات وارد شدی ولی متخصص نیستی، ادمین شهرت را عضو می‌کند.',
        ),
      );
    }

    final pid = auth.effectiveProviderId!;
    final previewing = auth.isPreviewingProvider;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('داشبورد متخصص'),
          if (previewing) ...[
            const SizedBox(width: 8),
            Chip(
              avatar: const Text('🛡️'),
              label: const Text('پیش‌نمایش ادمین', style: TextStyle(fontSize: 10.5)),
              padding: EdgeInsets.zero,
            ),
          ],
        ]),
        actions: previewing
            ? [
                TextButton(
                  onPressed: () {
                    auth.exitProviderPreview();
                    context.go('/a/home');
                  },
                  child: const Text('← خروج از پیش‌نمایش'),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<ProviderProfile?>(
        stream: repo.providers.watchProfile(pid),
        builder: (_, pSnap) {
          final p = pSnap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // کارت پروفایل
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      EmojiBadge(p?.emoji ?? '🧑‍🔧', seed: pid, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(p?.name ?? '…',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16)),
                                ),
                                if (p?.level == 'برتر') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('⭐ برتر',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warning)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (p != null) RatingStars(p.rating, showValue: true),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (p?.verified == true)
                                  const Text('✅ هویت تایید شده',
                                      style: TextStyle(
                                          fontSize: 11, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Text('آنلاین',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.subtext)),
                          Switch(
                            value: p?.online ?? true,
                            onChanged: (v) => repo.providers.setOnline(pid, v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // آمار
              StreamBuilder<List<EarningEntry>>(
                stream: repo.providers.watchEarnings(pid),
                builder: (_, eSnap) {
                  final monthIncome = (eSnap.data ?? [])
                      .fold<int>(0, (sum, e) => sum + e.amount);
                  return StreamBuilder<List<Booking>>(
                    stream: repo.bookings.watchProviderJobs(pid),
                    builder: (_, jSnap) {
                      final jobs = jSnap.data ?? [];
                      final today = jobs
                          .where((b) => b.dayLabel == 'امروز' && b.status.isActive)
                          .length;
                      return StreamBuilder<List<Booking>>(
                        stream: repo.bookings.watchProviderRequests("urmia"),
                        builder: (_, rSnap) {
                          final requests = (rSnap.data ?? []).length;
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.55,
                            children: [
                              StatCard(
                                  emoji: '💰',
                                  title: 'درآمد این ماه',
                                  value: faPrice(monthIncome),
                                  color: AppColors.success),
                              StatCard(
                                  emoji: '🛠️',
                                  title: 'کارهای امروز',
                                  value: toFaDigits(today)),
                              StatCard(
                                  emoji: '📥',
                                  title: 'درخواست جدید',
                                  value: toFaDigits(requests),
                                  color: AppColors.warning),
                              StatCard(
                                  emoji: '⭐',
                                  title: 'امتیاز من',
                                  value: toFaDigits(
                                      (p?.rating ?? 0).toStringAsFixed(1)),
                                  color: AppColors.info),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // کار امروز
              const SectionHeader('برنامه‌ی امروز'),
              const SizedBox(height: 10),
              StreamBuilder<List<Booking>>(
                stream: repo.bookings.watchProviderJobs(pid),
                builder: (_, snap) {
                  final todayJobs = (snap.data ?? [])
                      .where((b) => b.dayLabel == 'امروز' && b.status.isActive)
                      .toList();
                  if (todayJobs.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('برای امروز کاری ثبت نشده — استراحت کنید ☕',
                              style: TextStyle(color: AppColors.subtext, fontSize: 12.5)),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final b in todayJobs)
                        BookingCard(
                          booking: b,
                          onTap: () => context.push('/order/${b.id}'),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/p/requests'),
                icon: const Icon(Icons.inbox_rounded),
                label: const Text('مشاهده‌ی درخواست‌های جدید بازار'),
              ),
            ],
          );
        },
      ),
    );
  }
}
