import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.effectiveProviderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('درآمد')),
        body: const EmptyState(
          emoji: '🔐',
          title: 'ابتدا به‌عنوان سرویس‌دهنده وارد شوید',
        ),
      );
    }
    final pid = auth.effectiveProviderId!;

    return Scaffold(
      appBar: AppBar(title: const Text('درآمد و تسویه 💰')),
      body: StreamBuilder<List<EarningEntry>>(
        stream: RepoHub.instance.providers.watchEarnings(pid),
        builder: (_, snap) {
          final list = snap.data ?? [];
          final settled = list
              .where((e) => e.settled)
              .fold<int>(0, (s, e) => s + e.amount);
          final pending = list
              .where((e) => !e.settled)
              .fold<int>(0, (s, e) => s + e.amount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موجودی قابل برداشت',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      faPrice(settled),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          avatar: const Text('⏳'),
                          label: Text(
                            'در انتظار تسویه: ${faPrice(pending, unit: false)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.white24,
                          side: BorderSide.none,
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.success,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'درخواست تسویه ثبت شد — تا ۲۴ ساعت آینده واریز می‌شود (دمو)',
                                ),
                              ),
                            );
                          },
                          child: const Text('تسویه حساب'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader('تراکنش‌های اخیر'),
              const SizedBox(height: 8),
              StreamBuilder<double>(
                stream: RepoHub.instance.misc.watchCommission(),
                builder: (_, cSnap) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '* مبالغ پس از کسر کمیسیون پلتفرم (${toFaDigits(((cSnap.data ?? .15) * 100).round())}٪) محاسبه شده‌اند',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.subtext,
                    ),
                  ),
                ),
              ),
              for (final e in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (e.settled ? AppColors.success : AppColors.warning)
                              .withValues(alpha: .12),
                      child: Text(e.settled ? '✅' : '⏳'),
                    ),
                    title: Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      e.dateLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtext,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PriceLabel(e.amount),
                        Text(
                          e.settled ? 'تسویه شد' : 'در انتظار',
                          style: TextStyle(
                            fontSize: 10,
                            color: e.settled
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
