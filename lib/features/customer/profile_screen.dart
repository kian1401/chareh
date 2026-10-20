import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';
import '../../shared/ui.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل من')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // کارت کاربر
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user == null
                  ? Column(
                      children: [
                        const Text('👋', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        const Text(
                          'هنوز وارد نشده‌اید',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/auth'),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('ورود / ثبت‌نام'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        EmojiBadge(user.avatarEmoji, seed: user.id, size: 54),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                toFaDigits(user.phone),
                                style: const TextStyle(
                                  color: AppColors.subtext,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await auth.signOut();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('خارج شدید')),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                          ),
                          tooltip: 'خروج',
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // کیف پول
          if (user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('💳', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'کیف پول',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          PriceLabel(user.walletBalance),
                        ],
                      ),
                    ),
                    if (RepoHub.instance.isMock)
                      FilledButton.tonal(
                        onPressed: () async {
                          // 💳 شارژ واقعی‌نما با پلهٔ بونس تنظیمات ادمین
                          final r = await RepoHub.instance.misc.chargeWallet(
                            user.id,
                            500000,
                          );
                          auth.refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${faPrice(r.total)} شارژ شد + ${faPrice(r.bonus)} هدیه 🎁',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('شارژ +'),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // علاقه‌مندی‌ها
          if (user != null && user.favorites.isNotEmpty) ...[
            const SectionHeader('علاقه‌مندی‌های من ❤️'),
            const SizedBox(height: 10),
            StreamBuilder<List<ServiceItem>>(
              stream: RepoHub.instance.catalog.watchServices(),
              builder: (_, snap) {
                final favs = (snap.data ?? [])
                    .where((s) => user.favorites.contains(s.id))
                    .toList();
                return SizedBox(
                  height: 205,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => ServiceCard(
                      service: favs[i],
                      width: 165,
                      onTap: () => context.push('/service/${favs[i].id}'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // منو
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'آدرس‌های من',
                  onTap: () => _addressesSheet(context),
                ),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'اعلان‌ها',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'دستیار هوشمند و پشتیبانی',
                  onTap: () => context.go('/c/assistant'),
                ),
                _MenuTile(
                  icon: Icons.description_outlined,
                  title: 'قوانین و مقررات',
                  onTap: () => _termsDialog(context),
                ),
                _MenuTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'تغییر پرتال (مشتری ⇄ متخصص ⇄ ادمین)',
                  onTap: () => context.go('/start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'چاره نسخه‌ی ۱٫۲ — ساخته‌شده با 🧡 برای ارومیه',
              style: TextStyle(color: AppColors.subtext, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _addressesSheet(BuildContext context) async {
    final auth = context.read<AuthState>();
    final list = await RepoHub.instance.misc.getAddresses(
      auth.user?.id ?? 'u_c1',
    );
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'آدرس‌های من 📍',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final a in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    a.text,
                    style: const TextStyle(fontSize: 12, height: 1.6),
                  ),
                  trailing: a.isDefault
                      ? const Text(
                          'پیش‌فرض',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _termsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeSheet(
        title: const Text('قوانین و مقررات 📜'),
        content: const SingleChildScrollView(
          child: Text(
            '۱) متخصصین چاره پس از احراز هویت و آموزش فعالیت می‌کنند.\n\n'
            '۲) لغو رزرو تا ۲ ساعت قبل از شروع سرویس بدون هزینه است.\n\n'
            '۳) در صورت نارضایتی، مبلغ طبق «ضمانت چاره» بازگردانده می‌شود.\n\n'
            '۴) پرداخت آنلاین تا تایید پایان کار نزد پلتفرم امانت می‌ماند.\n\n'
            '۵) کمیسیون پلتفرم از مبلغ سرویس و توسط ادمین قابل تنظیم است.',
            style: TextStyle(height: 1.9, fontSize: 13),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 14,
        color: AppColors.subtext,
      ),
    );
  }
}
