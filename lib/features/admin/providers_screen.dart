import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../core/utils/persian_utils.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 🧑‍🔧 مدیریت کامل متخصصان — ایجاد/ویرایش/حذف/تایید + ورود به پنل ایشان
class AdminProvidersScreen extends StatelessWidget {
  const AdminProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متخصصان شهر')),
      body: StreamBuilder<List<ProviderProfile>>(
        stream: RepoHub.instance.providers.watchAll(),
        builder: (_, snap) {
          final list = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '📌 هر متخصص با شماره‌اش به اپ وصل می‌شود؛ سفارش‌های شهر شناخته می‌شود و امتیازهاش بر اساس نظر واقعی مشتری‌هاست.',
                  style: TextStyle(fontSize: 12, height: 1.8),
                ),
              ),
              if (list.isEmpty)
                const PillowCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'هنوز متخصصی تعریف نشده — با «تعریف متخصص» شروع کنید 🌱',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.8),
                      ),
                    ),
                  ),
                ),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProviderCard(p: p),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProvider(context, null),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('تعریف متخصص'),
      ),
    );
  }

  static Future<void> _editProvider(
    BuildContext context,
    ProviderProfile? p,
  ) async {
    final repo = RepoHub.instance;
    final cities = await repo.catalog.watchCities(activeOnly: false).first;
    final cats = await repo.catalog.watchCategories().first;
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final phoneCtrl = TextEditingController(text: p?.phone ?? '');
    final emojiCtrl = TextEditingController(text: p?.emoji ?? '🧑‍🔧');
    String cityId = p?.cityId ?? cities.first.id;
    final Set<String> skills = {...(p?.skills ?? <String>[])};
    bool verified = p?.verified ?? true;
    String level = p?.level ?? 'حرفه‌ای';

    // 🩹 روی وب/اCanvasKit، پاپ AlertDialog باعث نابودی سرفیس رندر می‌شد — باتم‌شیت سالم است
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setIn) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p == null ? '🌱 تعریف متخصص جدید' : 'ویرایش «${p.name}»',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'نام کامل'),
                ),
                TextField(
                  controller: phoneCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل (کلید ورود به اپ متخصص)',
                    counterText: '',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emojiCtrl,
                        decoration: const InputDecoration(labelText: 'اموجی'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: level,
                        decoration: const InputDecoration(
                          labelText: 'سطح کاری',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'مبتدی',
                            child: Text('مبتدی'),
                          ),
                          DropdownMenuItem(
                            value: 'حرفه‌ای',
                            child: Text('حرفه‌ای'),
                          ),
                          DropdownMenuItem(
                            value: 'برتر',
                            child: Text('برتر ⭐'),
                          ),
                        ],
                        onChanged: (v) => setIn(() => level = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: cityId,
                  decoration: const InputDecoration(labelText: 'شهر فعالیت'),
                  items: [
                    for (final c in cities)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.active ? "✅" : "🔒"} ${c.title}'),
                      ),
                  ],
                  onChanged: (v) => setIn(() => cityId = v!),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'مهارت‌ها (از دسته‌های فعال):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in cats)
                      FilterChip(
                        label: Text(
                          '${c.emoji} ${c.title}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: skills.contains(c.title),
                        onSelected: (_) => setIn(() {
                          skills.contains(c.title)
                              ? skills.remove(c.title)
                              : skills.add(c.title);
                        }),
                      ),
                  ],
                ),
                SwitchListTile(
                  dense: true,
                  value: verified,
                  onChanged: (v) => setIn(() => verified = v),
                  title: const Text('✅ تایید هویت و مدارک'),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('انصراف'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ذخیره'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      final updated = ProviderProfile(
        id: p?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        emoji: emojiCtrl.text.trim().isEmpty ? '🧑‍🔧' : emojiCtrl.text.trim(),
        skills: skills.toList(),
        cityId: cityId,
        verified: verified,
        level: level,
        rating: p?.rating ?? 0,
        ratingCount: p?.ratingCount ?? 0,
        jobsDone: p?.jobsDone ?? 0,
        active: p?.active ?? true,
        online: p?.online ?? true,
      );
      await RepoHub.instance.providers.upsertProvider(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ متخصص ذخیره شد — با شماره‌اش می‌تواند وارد شود'),
          ),
        );
      }
    }
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.p});
  final ProviderProfile p;

  @override
  Widget build(BuildContext context) {
    return PillowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SmartIcon(emoji: p.emoji, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (p.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                        ],
                        if (!p.active) ...[
                          const SizedBox(width: 6),
                          const Chip(
                            label: Text(
                              'غیرفعال',
                              style: TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${p.phone} • ${p.skills.take(2).join('، ')} • ⭐ ${toFaDigits(p.rating.toStringAsFixed(1))} (${toFaDigits(p.ratingCount)}) • ${toFaDigits(p.jobsDone)} کار',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => AdminProvidersScreen._editProvider(context, p),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('ویرایش'),
              ),
              const SizedBox(width: 8),
              // 👀 ورود به پنل متخصص (پیش‌نمایش زنده)
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: !p.active
                      ? null
                      : () {
                          context.read<AuthState>().enterProviderPreview(p.id);
                          context.go('/p/home');
                        },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('ورود به پنل 👀'),
                ),
              ),
              Tooltip(
                message: 'فعال/غیرفعال',
                child: Switch(
                  value: p.active,
                  onChanged: (v) => v
                      ? RepoHub.instance.providers.upsertProvider(
                          p..active = true,
                        )
                      : RepoHub.instance.providers.removeProvider(p.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
