import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/persian_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_state.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 🏠 خانه‌ی مشتری — طراحی گرم و سرزنده به سبک اپ‌های موفق خدمات منزل
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── هیروی گرم با سلام شخصی ──
          SliverAppBar(
            expandedHeight: 226,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // گرادیان غروب + دو حلقهٔ تزئینی روشن برای حس عمق ✨
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8A50), Color(0xFFE85C24), Color(0xFFC2451A)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                  if (theme.heroImageUrl.isNotEmpty)
                    Opacity(
                      opacity: .28,
                      child: Image.network(theme.heroImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  const Positioned(top: -60, left: -40, child: _Glow(size: 210, alpha: .16)),
                  const Positioned(bottom: 10, right: -50, child: _Glow(size: 160, alpha: .12)),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .22),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(children: [
                                Text(theme.logoEmoji, style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 5),
                                Text(theme.appTitle,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(width: 5),
                                StreamBuilder<List<City>>(
                                  stream: RepoHub.instance.catalog.watchCities(),
                                  builder: (_, snap) {
                                    final cities = snap.data?.where((c) => c.active).toList() ?? [];
                                    return GestureDetector(
                                      onTap: () => _citySheet(),
                                      child: Row(children: [
                                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text(cities.isNotEmpty ? cities.first.title : '',
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        const Icon(Icons.expand_more_rounded, size: 14, color: Colors.white70),
                                      ]),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          Text('سلام ${user?.name.isNotEmpty == true ? user!.name : 'دوست من'} 👋',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('امروز خانه‌ات به چه دستی نیاز دارد؟ ✨',
                              style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.6)),
                          const SizedBox(height: 16),
                          // 🔍 جستجوی برجسته داخل هیرو (الگوی اپ‌های موفق)
                          GestureDetector(
                            onTap: () => context.go('/c/services'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 6)),
                                ],
                              ),
                              child: const Row(children: [
                                Icon(Icons.search_rounded, color: AppColors.primary),
                                SizedBox(width: 10),
                                Text('ماشین لباس‌شویی، نقاشی، تخلیهٔ نفت...',
                                    style: TextStyle(color: AppColors.subtext, fontSize: 13)),
                                Spacer(),
                                Icon(Icons.tune_rounded, color: AppColors.subtext, size: 19),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── نوار اعتماد (آمار زندهٔ بازار) ───
                  _trustStrip(),
                  const SizedBox(height: 20),

                  SectionTitle('دسته‌بندی خدمات', action: TextButton(
                    onPressed: () => context.go('/c/services'),
                    child: const Text('همهٔ سرویس‌ها ←'),
                  )),
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
                        ratio: deviceTypeOf(context) == DeviceType.phone ? 0.84 : 0.92,
                        item: (i) => _categoryCard(cats[i]),
                      );
                    },
                  ),

                  const SizedBox(height: 22),
                  if (user != null) _referralBanner(user),
                  if (user != null) const SizedBox(height: 14),
                  _walletBanner(theme.settings),

                  const SizedBox(height: 24),
                  const SectionTitle('متخصصان همین نزدیکی 🌟'),
                  const SizedBox(height: 4),
                  _providersRail(),

                  const SizedBox(height: 26),
                  const SectionTitle('چرا خانه‌دارها چاره را دوست دارند؟ 💛'),
                  const SizedBox(height: 4),
                  _whyUs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 آمار زنده: متخصص فعال + کار انجام‌شده + میانگین امتیاز
  Widget _trustStrip() {
    return StreamBuilder<List<ProviderProfile>>(
      stream: RepoHub.instance.providers.watchAll(),
      builder: (_, snap) {
        final pros = (snap.data ?? []).where((p) => p.active).toList();
        final jobs = pros.fold<int>(0, (a, p) => a + p.jobsDone);
        final rated = pros.where((p) => p.ratingCount > 0).toList();
        final avg = rated.isEmpty
            ? null
            : rated.fold<double>(0, (a, p) => a + p.rating) / rated.length;
        final stats = <(String, String, IconData, Color)>[
          (toFaDigits(pros.length), 'متخصص فعال', Icons.engineering_rounded, AppColors.primary),
          (toFaDigits(jobs), 'کار تمام‌شده', Icons.task_alt_rounded, AppColors.success),
          (avg == null ? '—' : toFaDigits(avg.toStringAsFixed(1)), 'میانگین امتیاز',
              Icons.star_rounded, AppColors.accent),
        ];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) Container(width: 1, height: 34, color: AppColors.border),
              Expanded(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(stats[i].$3, size: 15, color: stats[i].$4),
                  const SizedBox(width: 4),
                  Text(stats[i].$1,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 2),
                Text(stats[i].$2, style: const TextStyle(fontSize: 10, color: AppColors.subtext)),
              ])),
            ],
          ]),
        );
      },
    );
  }

  Widget _categoryCard(Category c) {
    return PillowCard(
      onTap: () => context.go('/c/services?cat=${c.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🖼️ تصویر گرم دسته — نیمهٔ بالای کارت
          Expanded(
            child: SmartIcon(emoji: c.emoji, imageUrl: c.effectiveImage, size: 400, radius: 20),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Center(
              child: Text(c.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _referralBanner(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFBC54D), Color(0xFFF5A524), Color(0xFFDD8A0B)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('دوستانت را به چاره دعوت کن',
                  style: TextStyle(color: Color(0xFF4A2E00), fontWeight: FontWeight.w900, fontSize: 14.5)),
              Text('هر دوتان کیف پول هدیه می‌گیرید — کد من: ${user.referralCode}',
                  style: const TextStyle(color: Color(0xFF6B4400), fontSize: 11.5, height: 1.6)),
            ]),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/c/wallet'),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('دعوت'),
          ),
        ],
      ),
    );
  }

  Widget _walletBanner(AppSettings s) {
    if (s.bonusTiers.isEmpty) return const SizedBox();
    return InkWell(
      onTap: () => context.push('/c/wallet'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withValues(alpha: .4), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('💰', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'کوپن شارژ والت فعال است — از ${s.bonusTiers.first.bonusPercent}٪ تا ${s.bonusTiers.last.bonusPercent}٪ عیدی!',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.6),
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  /// 🌟 ریل متخصصان — اعتماد اجتماعی (امتیاز + کار انجام‌شده + تیک آبی)
  Widget _providersRail() {
    return StreamBuilder<List<ProviderProfile>>(
      stream: RepoHub.instance.providers.watchAll(),
      builder: (_, snap) {
        final pros = (snap.data ?? []).where((p) => p.active).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        if (pros.isEmpty) {
          return const PillowCard(
            padding: EdgeInsets.all(14),
            child: Text('به‌زودی متخصصان معرفی‌شدهٔ ادمین اینجا می‌آیند 🌱',
                style: TextStyle(color: AppColors.subtext, fontSize: 12.5)),
          );
        }
        return SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pros.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = pros[i];
              return Container(
                width: 118,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  Stack(children: [
                    SmartIcon(emoji: p.emoji, size: 52, radius: 16),
                    if (p.verified)
                      const Positioned(bottom: 0, left: 0,
                          child: CircleAvatar(radius: 8, backgroundColor: Colors.white,
                              child: Icon(Icons.verified, size: 15, color: Color(0xFF2563EB)))),
                  ]),
                  const SizedBox(height: 6),
                  Text(p.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
                    const SizedBox(width: 2),
                    Text('${toFaDigits(p.rating.toStringAsFixed(1))} · ${toFaDigits(p.jobsDone)} کار',
                        style: const TextStyle(fontSize: 9.5, color: AppColors.subtext)),
                  ]),
                ]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _whyUs() {
    final items = <(String, String, String, Color)>[
      ('🛡️', 'گارانتی ۹۰ روزه', 'تعمیرات لوازم خانگی', const Color(0xFFFFF1E8)),
      ('💳', 'پرداخت امن', 'با کیف پول + عیدی', const Color(0xFFFFF9E6)),
      ('⏰', 'زمان‌بندی منعطف', 'چند روز و بازهٔ پیشنهادی', const Color(0xFFEAF7F1)),
      ('🤖', 'دستیار هوشمند', 'عیب‌یابی تمام‌وقت', const Color(0xFFEDF4FF)),
    ];
    return AdaptiveGrid(
      count: items.length,
      ratio: 1.55,
      item: (i) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: items[i].$4,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(items[i].$1, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(items[i].$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          Text(items[i].$3,
              style: const TextStyle(fontSize: 9.5, color: AppColors.subtext), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  void _citySheet() {
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
                  trailing: c.active ? const Icon(Icons.check_circle, color: AppColors.success) : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// حلقهٔ نور تزئینی هیرو
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}
