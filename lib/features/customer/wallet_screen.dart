import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 💳 کیف پول واقعی‌نما — شارژ + بونس پلکانی + تراکنش + کد دعوت + شبکه‌ها
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _amount = 100000;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('کیف پول')),
        body: const NeedLogin(emoji: '💳', title: 'برای دیدن کیف پول وارد شوید'),
      );
    }
    final user = auth.user!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('کیف پول و امتیاز')),
      body: StreamBuilder<AppSettings>(
        stream: RepoHub.instance.misc.watchSettings(),
        builder: (_, ss) {
          final s = ss.data ?? AppSettings();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── کارت موجودی ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('موجودی کیف پول', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(faPrice(user.walletBalance),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Chip(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      label: Text('⭐ ${toFaDigits(user.points)} امتیاز',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      label: Text('📞 ${toFaDigits(user.phone.substring(0, 7))}***',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // ── شارژ + بونس ──
              const SectionTitle('شارژ کیف پول 💰'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final v in const [50000, 100000, 300000, 500000, 1000000])
                  ChoiceChip(
                    label: Text(faPrice(v)),
                    selected: _amount == v,
                    onSelected: (_) => setState(() => _amount = v),
                  ),
              ]),
              const SizedBox(height: 12),
              _bonusHint(s),
              FilledButton.icon(
                onPressed: _busy ? null : () => _charge(user),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(_busy ? 'در حال شارژ...' : 'شارژ کن (درگاه آزمایشی 🧪)'),
              ),
              const SizedBox(height: 24),

              // ── دعوت از دوستان ──
              const SectionTitle('دعوت از دوستان 🎁'),
              PillowCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('کد دعوت من: ${user.referralCode}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    'وقتی دوستت با این کد ثبت‌نام کرد هر دوندونیه هدیه می‌گیرید: شما ${faPrice(s.referralReward)} و او ${faPrice(s.referralReward ~/ 2)}! 🎁 کد را در تلگرام یا واتساپ بفرستید:',
                    style: const TextStyle(fontSize: 12.5, height: 1.8),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: 'من را به چاره دعوت کن! کد من: ${user.referralCode} — دانلود: chareh-web.onrender.com 🧩'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('📋 متن دعوت کپی شد — در تلگرام/واتساپ بفرست')));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('کپی لینک دعوت'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // 📱 شبکه‌های اجتماعی (محل اتصال آینده — ثبت سفارش از آن‌ها)
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _socialChip('تلگرام چاره ✈️', s.telegramUrl),
                    _socialChip('اینستاگرام 📸', s.instagramUrl),
                    _socialChip('واتساپ 🟢', s.whatsappUrl),
                    if (s.socialOrderComingSoon)
                      chip(const Chip(
                        avatar: Text('🔜'),
                        label: Text('ثبت سفارش از شبکه‌ها به‌زودی', style: TextStyle(fontSize: 11.5)),
                      )),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              // ── تراکنش‌ها ──
              const SectionTitle('تراکنش‌های کیف پول 📜'),
              StreamBuilder<List<WalletTxn>>(
                stream: RepoHub.instance.misc.watchWallet(user.id),
                builder: (_, tx) {
                  final list = tx.data ?? [];
                  if (list.isEmpty) {
                    return const PillowCard(
                        child: Center(child: Text('هنوز تراکنشی ثبت نشده — اولین شارژت را بزن! 🚀')));
                  }
                  return Column(children: [
                    for (final t in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PillowCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Text(t.amount >= 0 ? (t.isBonus ? '🎁' : '➕') : '➖',
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.title, style: const TextStyle(fontSize: 12.5, height: 1.6))),
                            Text(faPrice(t.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: t.amount >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                )),
                          ]),
                        ),
                      ),
                  ]);
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget chip(Widget w) => w;

  Widget _bonusHint(AppSettings s) {
    final tier = [...s.bonusTiers]..sort((a, b) => b.minAmount.compareTo(a.minAmount));
    final best = tier.where((t) => _amount >= t.minAmount).firstOrNull;
    final percent = best?.bonusPercent ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: percent > 0 ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          percent > 0
              ? '🎁 با این شارژ ${toFaDigits(percent)}٪ بونس می‌گیری: ${faPrice((_amount * percent / 100).round())}'
              : '💡 با شارژ ${faPrice(s.bonusTiers.isNotEmpty ? s.bonusTiers.first.minAmount : 100000)} یا بیشتر، بونس می‌گیری',
          style: TextStyle(fontSize: 12.5, height: 1.7, fontWeight: percent > 0 ? FontWeight.w700 : FontWeight.w400),
        ),
      ),
    );
  }

  Widget _socialChip(String label, String url) => ActionChip(
        avatar: const Text('📱'),
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        onPressed: url.isEmpty
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('لینک کپی شد')));
              },
      );

  Future<void> _charge(AppUser user) async {
    setState(() => _busy = true);
    final res = await RepoHub.instance.misc.chargeWallet(user.id, _amount);
    if (!mounted) return;
    setState(() => _busy = false);
    context.read<AuthState>().refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.bonus > 0
            ? '✅ شارژ شد + بونس ${faPrice(res.bonus)} هدیه!'
            : '✅ کیف پول شارژ شد: ${faPrice(res.total)}'),
      ),
    );
  }
}
