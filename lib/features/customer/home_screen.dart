import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;
    final auth = context.watch<AuthState>();
    final userId = auth.user?.id ?? 'u_c1';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('چاره 🏙️',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('📍 تهران — سعادت‌آباد',
                style: TextStyle(fontSize: 11, color: AppColors.subtext)),
          ],
        ),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: repo.misc.watchNotifications(userId),
            builder: (_, snap) {
              final unread = (snap.data ?? []).where((n) => n.unread).length;
              return IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(toFaDigits(unread)),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 8),
          Text('سلام ${auth.user?.name.split(' ').first ?? 'مهمان'} 👋',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('امروز چه خدمتی لازم دارید؟',
              style: TextStyle(color: AppColors.subtext, fontSize: 13.5)),
          const SizedBox(height: 16),

          // جستجو
          InkWell(
            onTap: () => context.go('/c/services?focus=1'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.subtext),
                  SizedBox(width: 10),
                  Text('مثلاً: نظافت منزل، سرویس کولر…',
                      style: TextStyle(color: AppColors.subtext, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // بنر تبلیغاتی
          InkWell(
            onTap: () => context.push('/service/s4'),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تابستان خنک با چاره ❄️',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15)),
                        SizedBox(height: 6),
                        Text('۲۵٪ تخفیف سرویس کولر آبی تا پایان هفته',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.7)),
                        SizedBox(height: 10),
                        Badge(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          label: Text('رزرو سرویس کولر',
                              style: TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const Text('💨', style: TextStyle(fontSize: 52)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('دسته‌بندی خدمات'),
          const SizedBox(height: 12),
          StreamBuilder<List<Category>>(
            stream: repo.catalog.watchCategories(),
            builder: (_, snap) {
              final cats = snap.data ?? [];
              return SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    return InkWell(
                      onTap: () => context.go('/c/services?cat=${c.id}'),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 74,
                        child: Column(
                          children: [
                            EmojiBadge(c.emoji, seed: c.id, size: 56),
                            const SizedBox(height: 6),
                            Text(c.title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, height: 1.4)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          SectionHeader('پرتقاضاترین سرویس‌ها',
              actionText: 'همه',
              onAction: () => context.go('/c/services')),
          const SizedBox(height: 12),
          StreamBuilder<List<ServiceItem>>(
            stream: repo.catalog.watchServices(),
            builder: (_, snap) {
              final list = (snap.data ?? [])
                ..sort((a, b) => b.jobsDone.compareTo(a.jobsDone));
              final top = list.take(8).toList();
              return SizedBox(
                height: 205,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: top.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ServiceCard(
                    service: top[i],
                    width: 165,
                    onTap: () => context.push('/service/${top[i].id}'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          const SectionHeader('متخصصین برتر'),
          const SizedBox(height: 12),
          StreamBuilder<List<ProviderProfile>>(
            stream: repo.catalog.watchProviders(),
            builder: (_, snap) {
              final list = (snap.data ?? [])
                ..sort((a, b) => b.rating.compareTo(a.rating));
              return SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ProviderCard(provider: list[i]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // اعتمادسازی
          const SectionHeader('چرا چاره؟'),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrustChip('✅ متخصص تاییدشده'),
              _TrustChip('🛡️ ضمانت انجام کار'),
              _TrustChip('💳 پرداخت امن'),
              _TrustChip('☎️ پشتیبانی ۲۴/۷'),
              _TrustChip('💜 بیمه مسئولیت'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
