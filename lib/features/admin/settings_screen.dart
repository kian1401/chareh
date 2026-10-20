import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';

/// ⚙️ تنظیمات CMS — برند، تم، فونت/آیکن، کیف پول، هوش مصنوعی، شبکه‌ها
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات سامانه'),
        actions: [
          IconButton(
            tooltip: 'خروج از پنل مدیریت',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthState>().signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: StreamBuilder<AppSettings>(
        stream: RepoHub.instance.misc.watchSettings(),
        builder: (_, snap) {
          var s = snap.data ?? AppSettings();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── برند و تم ──
              _section('🎨 برند و ظاهر', [
                _editableRow(
                  context,
                  s,
                  'عنوان اپ',
                  s.appTitle,
                  (v) => s.appTitle = v,
                  icon: Icons.title_rounded,
                ),
                _editableRow(
                  context,
                  s,
                  'اموجی/لوگوی برند',
                  s.logoEmoji,
                  (v) => s.logoEmoji = v,
                  icon: Icons.emoji_emotions_rounded,
                ),
                _editableRow(
                  context,
                  s,
                  'لینک تصویر هیرو (صفحه‌ی نخست)',
                  s.heroImageUrl,
                  (v) => s.heroImageUrl = v,
                  icon: Icons.image_rounded,
                  ltr: true,
                ),
                const SizedBox(height: 12),
                const Text(
                  'رنگ اصلی تم:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hex in const [
                      '#6D28D9',
                      '#0F766E',
                      '#DC2626',
                      '#0284C7',
                      '#D97706',
                      '#0891B2',
                      '#7C3AED',
                      '#111827',
                    ])
                      GestureDetector(
                        onTap: () => _save(s..primaryHex = hex),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(hex.replaceFirst('#', '0xFF')),
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: s.primaryHex == hex
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: s.primaryHex == hex
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ]),

              const SizedBox(height: 16),

              // ── هوش مصنوعی متخصص ──
              _section('🤖 دستیار هوشمند (متخصص)', [
                _editableRow(
                  context,
                  s,
                  'کلید Gemini API',
                  s.geminiApiKey.isEmpty ? '' : '🔐 ذخیره شده',
                  (v) => s.geminiApiKey = v,
                  icon: Icons.vpn_key_rounded,
                  secret: true,
                ),
                const Text(
                  'با کلید Gemini، دستیار متخصص از مدل واقعی عیب‌یابی استفاده می‌کند (تحلیل تصویر نقشه و تشخیص لوازم خانگی). در غیر این صورت کارشناس آفلاین پاسخ می‌دهد.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                    height: 1.7,
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // ── کیف پول و بونس ──
              _section('💳 کیف پول و بونس‌های شارژ', [
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'پاداش کامل دعوت موفق',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  trailing: Text(faPrice(s.referralReward)),
                  onTap: () => _editNumber(
                    context,
                    s,
                    'پاداش دعوت موفق (تومان)',
                    s.referralReward,
                    (v) => s.referralReward = v,
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'درصد کمیسیون پلتفرم',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  trailing: Text('${(s.commissionRate * 100).round()}٪'),
                  onTap: () => _editNumber(
                    context,
                    s,
                    'کمیسیون (درصد)',
                    (s.commissionRate * 100).round(),
                    (v) => s.commissionRate = v / 100,
                  ),
                ),
                const Divider(),
                const Text(
                  'پلکات بونس شارژ (کمترین مبلغ → اول هم بونس):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in s.bonusTiers)
                      Chip(
                        key: ValueKey(t.id),
                        label: Text(
                          'جمع ≥ ${faGrouped(t.minAmount)} → +${t.bonusPercent}٪',
                        ),
                        onDeleted: () => _save(s..bonusTiers.remove(t)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _addBonusTier(context, s),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('افزودن پلهٔ بونس'),
                ),
              ]),

              const SizedBox(height: 16),

              // ── شبکه‌های اجتماعی ──
              _section('📱 شبکه‌های اجتماعی چاره', [
                _editableRow(
                  context,
                  s,
                  'لینک تلگرام ✈️',
                  s.telegramUrl,
                  (v) => s.telegramUrl = v,
                  icon: Icons.telegram_rounded,
                  ltr: true,
                ),
                _editableRow(
                  context,
                  s,
                  'لینک اینستاگرام 📸',
                  s.instagramUrl,
                  (v) => s.instagramUrl = v,
                  icon: Icons.camera_alt_rounded,
                  ltr: true,
                ),
                _editableRow(
                  context,
                  s,
                  'واتساپ 🟢',
                  s.whatsappUrl,
                  (v) => s.whatsappUrl = v,
                  icon: Icons.chat_rounded,
                  ltr: true,
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: s.socialOrderComingSoon,
                  onChanged: (v) => _save(s..socialOrderComingSoon = v),
                  title: const Text(
                    'نمایش «ثبت سفارش از شبکه‌ها به‌زودی» 🔜',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ]),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return PillowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _editableRow(
    BuildContext context,
    AppSettings s,
    String label,
    String value,
    void Function(String) setter, {
    IconData? icon,
    bool ltr = false,
    bool secret = false,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: icon == null ? null : Icon(icon, size: 18),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
        textDirection: ltr ? TextDirection.ltr : null,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.edit_rounded, size: 16),
      onTap: () =>
          _editString(context, s, label, value, setter, secret: secret),
    );
  }

  void _editString(
    BuildContext context,
    AppSettings s,
    String label,
    String value,
    void Function(String) setter, {
    bool secret = false,
  }) {
    final ctrl = TextEditingController(text: secret ? '' : value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeSheet(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              setter(ctrl.text.trim());
              _save(s);
              Navigator.pop(context);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _editNumber(
    BuildContext context,
    AppSettings s,
    String label,
    int value,
    void Function(int) setter,
  ) {
    _editString(
      context,
      s,
      label,
      '$value',
      (v) => setter(int.tryParse(v) ?? value),
    );
  }

  void _addBonusTier(BuildContext context, AppSettings s) async {
    final minCtrl = TextEditingController(text: '200000');
    final pctCtrl = TextEditingController(text: '10');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeSheet(
        title: const Text('پلهٔ بونس جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'حداقل مبلغ شارژ (تومان)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'درصد بونس'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _save(
        s
          ..bonusTiers.add(
            WalletBonusTier(
              id: 't_${DateTime.now().millisecondsSinceEpoch}',
              minAmount: int.tryParse(minCtrl.text) ?? 0,
              bonusPercent: int.tryParse(pctCtrl.text) ?? 0,
            ),
          ),
      );
    }
  }

  void _save(AppSettings s) {
    RepoHub.instance.misc.saveSettings(s);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 900),
        content: Text('✅ ذخیره شد — زنده روی همه‌ی نمایشگرها ✅'),
      ),
    );
  }
}
