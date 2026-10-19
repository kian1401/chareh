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

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final repo = RepoHub.instance;

    if (auth.effectiveProviderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('پروفایل متخصص')),
        body: const NeedLogin(emoji: '🧑‍🔧', title: 'حساب متخصص لازم است'),
      );
    }
    final pid = auth.effectiveProviderId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل متخصص'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/start');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: StreamBuilder<ProviderProfile?>(
        stream: repo.providers.watchProfile(pid),
        builder: (_, snap) {
          final p = snap.data;
          if (p == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      EmojiBadge(p.emoji, seed: p.id, size: 72, radius: 22),
                      const SizedBox(height: 10),
                      Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 6),
                      RatingStars(p.rating, showValue: true, size: 18),
                      const SizedBox(height: 8),
                      Text('${toFaDigits(p.jobsDone)} سرویس انجام‌شده از طریق چاره',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.subtext)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('مهارت‌های من'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in p.skills)
                            Chip(
                              label: Text(s, style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _DocTile('کارت ملی و احراز هویت', true),
                    _DocTile('گواهی عدم سوءپیشینه', true),
                    _DocTile('مدرک فنی و حرفه‌ای', true),
                    _DocTile('عکس پرسنلی', p.verified),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.percent_rounded, color: AppColors.primary),
                      title: const Text('تعرفه‌ها و کمیسیون',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: StreamBuilder<double>(
                        stream: repo.misc.watchCommission(),
                        initialData: .15,
                        builder: (_, s) => Text(
                            'کمیسیون فعلی پلتفرم: ${toFaDigits(((s.data ?? .15) * 100).round())}٪ از هر سفارش',
                            style: const TextStyle(fontSize: 11.5)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.swap_horiz_rounded,
                          color: AppColors.primary),
                      title: const Text('تغییر پرتال',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      onTap: () => context.go('/start'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile(this.title, this.done);
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        done ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
        color: done ? AppColors.success : AppColors.warning,
      ),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Text(done ? 'تایید شد' : 'در بررسی',
          style: TextStyle(
              fontSize: 11,
              color: done ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w700)),
    );
  }
}
