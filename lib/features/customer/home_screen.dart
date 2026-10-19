import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/persian_utils.dart';
import '../../core/theme/theme_state.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 🏠 خانه‌ی مشتری — طراحی مدرن با تصویر، شهر فعال، دعوت از دوستان
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = context.watch<ThemeState>();
    final user = auth.user;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── هیرو مدرن ──
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(right: 16, bottom: 14),
              title: Row(children: [
                Text(theme.logoEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(theme.appTitle,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.55)],
                    begin: Alignment.topRight, end: Alignment.bottomLeft,
                  ),
                ),
                child: Stack(children: [
                  if (theme.heroImageUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(theme.heroImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  Positioned.fill(
                    child: Container(color: primary.withValues(alpha: 0.32)),
                  ),
                ]),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── جستجو + شهر ───
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/c/services'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEDEAF6)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                              SizedBox(width: 8),
                              Text('دنبال چه خدمتی هستی؟', style: TextStyle(color: Color(0xFF9CA3AF))),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 🏙️ نمایش شهر فعال
                      StreamBuilder<List<City>>(
                        stream: RepoHub.instance.catalog.watchCities(),
                        builder: (_, snap) {
                          final cities = snap.data?.where((c) => c.active).toList() ?? [];
                          return ActionChip(
                            avatar: const Text('🏙️'),
                            label: Text(cities.isNotEmpty ? cities.first.title : '...'),
                            onPressed: () => _citySheet(cities.firstOrNull),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (user != null) _welcome(user),
                  const SizedBox(height: 16),
                  const SectionTitle('دسته‌بندی‌ها 🧰'),
                  StreamBuilder<List<Category>>(
                    stream: RepoHub.instance.catalog.watchCategories(),
                    builder: (_, snap) {
                      final cats = snap.data ?? [];
                      if (cats.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return AdaptiveGrid(
                        count: cats.length,
                        ratio: deviceTypeOf(context) == DeviceType.phone ? 0.92 : 0.98,
                        item: (i) => _categoryCard(cats[i]),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  // 🎁 دعوت از دوستان
                  if (user != null) _referralBanner(user, primary),

                  const SizedBox(height: 20),
                  // 💳 بنر بونس کیف پول
                  _walletBanner(theme.settings, primary),

                  const SizedBox(height: 20),
                  const SectionTitle('چرا چاره؟ ✨'),
                  _whyUs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome(AppUser user) {
    return Row(children: [
      Text('سلام ${user.name} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    ]);
  }

  Widget _categoryCard(Category c) {
    return PillowCard(
      onTap: () => context.go('/c/services?cat=${c.id}'),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🖼️ تصویر یا اموجی — هوشمند
          SmartIcon(emoji: c.emoji, imageUrl: c.imageUrl, size: 54, radius: 16),
          const SizedBox(height: 10),
          Text(c.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.5)),
        ],
      ),
    );
  }

  Widget _referralBanner(AppUser user, Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.75)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('دوستانت را به چاره دعوت کن',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('هر دو کیف پول هدیه می‌گیرید. کد من: ${user.referralCode}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
            ]),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/c/wallet'),
            icon: const Icon(Icons.share_rounded),
            label: const Text('دعوت'),
          ),
        ],
      ),
    );
  }

  Widget _walletBanner(AppSettings s, Color primary) {
    if (s.bonusTiers.isEmpty) return const SizedBox();
    return InkWell(
      onTap: () => context.push('/c/wallet'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'شارژ والت = هدیه! از ${s.bonusTiers.first.bonusPercent}٪ تا ${s.bonusTiers.last.bonusPercent}٪ بونس',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _whyUs() {
    final items = [
      ('🛡️', 'گارانتی ۹۰ روزه', 'تعمیرات لوازم خانگی'),
      ('💳', 'پرداخت امن', 'البته با کیف پول بونس'),
      ('⏰', 'زمان‌بندی انعطاف', 'چند روز/بازه پیشنهادی'),
      ('🤖', 'هوش مصنوعی', 'عیب‌یابی تمام‌وقت'),
    ];
    return AdaptiveGrid(
      count: items.length,
      ratio: 1.6,
      item: (i) => PillowCard(
        padding: const EdgeInsets.all(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(items[i].$1, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(items[i].$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          Text(items[i].$3, style: const TextStyle(fontSize: 9.5, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _citySheet(City? active) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StreamBuilder<List<City>>(
        stream: RepoHub.instance.catalog.watchCities(activeOnly: false),
        builder: (_, snap) {
          final cities = snap.data ?? [];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('شهر خود را انتخاب کنید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              for (final c in cities)
                ListTile(
                  leading: Text(c.active ? '✅' : '🔒', style: const TextStyle(fontSize: 20)),
                  title: Text(c.title),
                  subtitle: Text(c.active ? c.province : 'به‌زودی در ${c.title}'),
                  trailing: c.active ? const Icon(Icons.check_circle, color: Color(0xFF059669)) : null,
                ),
            ],
          );
        },
      ),
    );
  }
}
