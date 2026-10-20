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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;
    final auth = context.watch<AuthState>();

    if (!context.watch<AuthState>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('داشبورد مدیریت')),
        body: const NeedLogin(
          emoji: '🛡️',
          title: 'به‌عنوان مدیر وارد شوید',
          hint: 'شرح حساب مدیر سیستم: با شمارهٔ موبایل پیش‌فرض مدیریت وارد شوید',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('داشبورد مدیریت 🛡️')),
      body: StreamBuilder<List<Booking>>(
        stream: repo.bookings.watchAll(),
        builder: (_, bSnap) {
          final bookings = bSnap.data ?? [];
          return StreamBuilder<List<ProviderProfile>>(
            stream: repo.catalog.watchProviders(),
            builder: (_, pSnap) {
              final providers = pSnap.data ?? [];
              return StreamBuilder<double>(
                stream: repo.misc.watchCommission(),
                initialData: .15,
                builder: (_, cSnap) {
                  final commission = cSnap.data ?? .15;
                  final completed =
                      bookings.where((b) => b.status == BookingStatus.completed).toList();
                  final gmv = completed.fold<int>(0, (s, b) => s + b.totalPrice);
                  final active = bookings.where((b) => b.status.isActive).length;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.55,
                        children: [
                          StatCard(
                              emoji: '💵',
                              title: 'گردش مالی (GMV)',
                              value: faPrice(gmv),
                              color: AppColors.success),
                          StatCard(
                              emoji: '🏦',
                              title: 'سهم پلتفرم',
                              value: faPrice((gmv * commission).round())),
                          StatCard(
                              emoji: '🛠️',
                              title: 'سفارش‌های فعال',
                              value: toFaDigits(active),
                              color: AppColors.warning),
                          StatCard(
                              emoji: '🧑‍🔧',
                              title: 'متخصصین فعال',
                              value: toFaDigits(providers.length),
                              color: AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // نمودار توزیع وضعیت‌ها
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader('وضعیت سفارش‌ها'),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 140,
                                child: _StatusChart(bookings: bookings),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // کمیسیون
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                  'کمیسیون پلتفرم: ${toFaDigits((commission * 100).round())}٪'),
                              Slider(
                                value: commission,
                                min: .05,
                                max: .30,
                                divisions: 25,
                                label: '${toFaDigits((commission * 100).round())}٪',
                                onChanged: (v) => RepoHub.instance.misc.setCommission(double.parse(v.toStringAsFixed(2))),
                              ),
                              const Text(
                                'این نرخ بلافاصله در محاسبات درآمد متخصصین اعمال می‌شود.',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.subtext),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _AdminQuickRow(),
                      const SizedBox(height: 16),
                      const SectionHeader('آخرین سفارش‌ها'),
                      const SizedBox(height: 8),
                      for (final b in bookings.take(5))
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading:
                                EmojiBadge(b.serviceEmoji, seed: b.serviceId, size: 40),
                            title: Text(b.serviceTitle,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${b.customerName} • ${b.dayLabel} ${b.timeSlot}',
                                style: const TextStyle(fontSize: 11.5)),
                            trailing: StatusChip(b.status),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    const statuses = BookingStatus.values;
    final counts = {
      for (final s in statuses) s: bookings.where((b) => b.status == s).length
    };
    final max = counts.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final s in statuses)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(toFaDigits(counts[s]),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 6 + (counts[s]! / max) * 84,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.fa,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 8.5, color: AppColors.subtext)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 🗂️ دسترسی سریع متخصصین/شهرها/تنظیمات (تا در نوار تب جا نگیرند)
class _AdminQuickRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, String)>[
      ('متخصصان', Icons.engineering_rounded, '/a/providers'),
      ('شهرها', Icons.location_city_rounded, '/a/cities'),
      ('تنظیمات', Icons.tune_rounded, '/a/settings'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('مدیریت سریع'),
      const SizedBox(height: 4),
      Row(children: [
        for (final it in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(it.$3),
                icon: Icon(it.$2, size: 17),
                label: Text(it.$1, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
      ]),
    ]);
  }
}
