import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';

/// 🗂️ مدیریت دسته‌بندی‌ها و سرویس‌ها — فعال/غیرفعال، افزودن، ویرایش، تصویر جای اموجی
class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دسته‌بندی‌ها و سرویس‌ها'),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: '🗂️ دسته‌بندی‌ها'),
          Tab(text: '🧰 سرویس‌ها (زیرمجموعه)'),
        ]),
      ),
      body: StreamBuilder<List<Category>>(
        stream: RepoHub.instance.catalog.watchCategories(includeHidden: true),
        builder: (_, catSnap) {
          final cats = catSnap.data ?? [];
          return StreamBuilder<List<ServiceItem>>(
            stream: RepoHub.instance.catalog.watchServices(includeHidden: true),
            builder: (_, svcSnap) {
              final services = svcSnap.data ?? [];
              return TabBarView(
                controller: _tab,
                children: [
                  _CategoriesTab(cats: cats, services: services),
                  _ServicesTab(services: services, cats: cats),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tab.index == 0 ? _editCategory(null) : _editService(null),
        icon: const Icon(Icons.add_rounded),
        label: Text(_tab.index == 0 ? 'دسته جدید' : 'سرویس جدید'),
      ),
    );
  }

  // ───── دیالوگ افزودن/ویرایش دسته ─────
  Future<void> _editCategory(Category? c) async {
    final titleCtrl = TextEditingController(text: c?.title ?? '');
    final emojiCtrl = TextEditingController(text: c?.emoji ?? '🛠️');
    final imgCtrl = TextEditingController(text: c?.imageUrl ?? '');
    final orderCtrl = TextEditingController(text: '${c?.order ?? 9}');
    bool featured = c?.featured ?? false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setIn) => SafeSheet(
          title: Text(c == null ? 'افزودن دسته‌بندی' : 'ویرایش «${c.title}»'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان دسته')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'اموجی جایگزین'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'ترتیب'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: imgCtrl,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'لینک تصویر (به‌جای اموجی) 🖼️',
                  hintText: 'https://...',
                ),
                onChanged: (_) => setIn(() {}),
              ),
              const SizedBox(height: 8),
              if (imgCtrl.text.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imgCtrl.text, height: 90, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text('⚠️ تصویر خوانا نیست')),
                ),
              SwitchListTile(
                value: featured,
                onChanged: (v) => setIn(() => featured = v),
                title: const Text('⭐ دسته ویژه در خانه؟'),
                dense: true,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final updated = Category(
        id: c?.id ?? RepoHub.instance.catalog.hashCode.toString(),
        title: titleCtrl.text.trim(),
        emoji: emojiCtrl.text.trim().isEmpty ? '🧰' : emojiCtrl.text.trim(),
        imageUrl: imgCtrl.text.trim(),
        active: c?.active ?? true,
        featured: featured,
        order: int.tryParse(orderCtrl.text) ?? 9,
      );
      await RepoHub.instance.catalog.upsertCategory(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ دسته ذخیره شد')));
      }
    }
  }

  // ───── دیالوگ افزودن/ویرایش سرویس — با گزینه‌های قیمتی چندگانه ─────
  Future<void> _editService(ServiceItem? s) async {
    final cats = await RepoHub.instance.catalog.watchCategories(includeHidden: true).first;
    String catId = s?.categoryId ?? (cats.isNotEmpty ? cats.first.id : '');
    final titleCtrl = TextEditingController(text: s?.title ?? '');
    final descCtrl = TextEditingController(text: s?.description ?? '');
    final emojiCtrl = TextEditingController(text: s?.emoji ?? '🔧');
    final imgCtrl = TextEditingController(text: s?.imageUrl ?? '');
    final priceCtrl = TextEditingController(text: '${s?.basePrice ?? 0}');
    final opts = (s != null)
        ? <Map<String, dynamic>>[
            for (final o in s.options)
              {
                'title': TextEditingController(text: o.title),
                'price': TextEditingController(text: '${o.price}'),
                'duration': TextEditingController(text: o.duration),
              }
          ]
        : <Map<String, dynamic>>[
            {'title': TextEditingController(), 'price': TextEditingController(text: '0'), 'duration': TextEditingController()}
          ];

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setIn) => SafeSheet(
          title: Text(s == null ? 'افزودن سرویس زیرمجموعه' : 'ویرایش سرویس'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: catId,
                  decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                  items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.title}'))],
                  onChanged: (v) => setIn(() => catId = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان سرویس')),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'توضیح')),
                Row(children: [
                  Expanded(child: TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'اموجی 💾'))),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child: TextField(controller: imgCtrl, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'لینک تصویر 🖼️'))),
                ]),
                TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'شروع قیمت از (تومان)')),
                const Divider(height: 24),
                Row(children: [
                  const Expanded(child: Text('🎛️ گزینه‌های قیمتی', style: TextStyle(fontWeight: FontWeight.w800))),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded),
                    tooltip: 'گزینهٔ جدید',
                    onPressed: () => setIn(() => opts.add({
                          'title': TextEditingController(),
                          'price': TextEditingController(text: '0'),
                          'duration': TextEditingController(),
                        })),
                  ),
                ]),
                for (var i = 0; i < opts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(flex: 3, child: TextField(controller: opts[i]['title'], decoration: InputDecoration(labelText: 'گزینه ${i + 1}: عنوان'))),
                      const SizedBox(width: 6),
                      Expanded(flex: 2, child: TextField(controller: opts[i]['price'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت'))),
                      const SizedBox(width: 6),
                      Expanded(flex: 2, child: TextField(controller: opts[i]['duration'], decoration: const InputDecoration(labelText: 'مدت'))),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        onPressed: opts.length > 1 ? () => setIn(() => opts.removeAt(i)) : null,
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره سرویس')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final item = ServiceItem(
        id: s?.id ?? 's_${DateTime.now().millisecondsSinceEpoch}',
        categoryId: catId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        emoji: emojiCtrl.text.trim().isEmpty ? '🔧' : emojiCtrl.text.trim(),
        basePrice: int.tryParse(priceCtrl.text) ?? 0,
        imageUrl: imgCtrl.text.trim(),
        active: s?.active ?? true,
        rating: s?.rating ?? 4.8,
        options: [
          for (var i = 0; i < opts.length; i++)
            if ((opts[i]['title'] as TextEditingController).text.trim().isNotEmpty)
              ServiceOption(
                id: 'opt$i',
                title: (opts[i]['title'] as TextEditingController).text.trim(),
                price: int.tryParse((opts[i]['price'] as TextEditingController).text) ?? 0,
                duration: (opts[i]['duration'] as TextEditingController).text.trim(),
              ),
        ],
        addOns: s?.addOns ?? [],
        tags: s?.tags ?? [],
      );
      await RepoHub.instance.catalog.upsertService(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ سرویس ذخیره شد')));
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}

// ───────────── تب دسته‌بندی‌ها ─────────────
class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({required this.cats, required this.services});
  final List<Category> cats;
  final List<ServiceItem> services;

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) return const _EmptyState('هنوز دسته‌ای نیست');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: const Text(
            '📌 دستهٔ غیرفعال برای مشتری و متخصص نمایش داده نمی‌شود؛ با ضربه روی دسته می‌توانی ویرایش، تصویر بگذاری یا حذف کنی.',
            style: TextStyle(fontSize: 12, height: 1.8),
          ),
        ),
        for (final c in cats)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PillowCard(
              child: Row(children: [
                SmartIcon(emoji: c.emoji, imageUrl: c.effectiveImage, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '${services.where((s) => s.categoryId == c.id).length} زیرمجموعه${c.featured ? ' • ویژه ⭐' : ''}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                  ]),
                ),
                IconButton(
                  tooltip: 'ویرایش',
                  onPressed: () {},
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
                // 🔀 فعال/غیرفعال زنده
                Switch(
                  value: c.active,
                  onChanged: (v) {
                    c.active = v;
                    RepoHub.instance.catalog.upsertCategory(c);
                  },
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  onPressed: () => _deleteCategory(context, c),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  void _deleteCategory(BuildContext context, Category c) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeSheet(
        title: const Text('حذف دسته؟'),
        content: Text('«${c.title}» حذف شود؟ سرویس‌های زیرمجموعه‌اش هم پنهان می‌شوند.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton.tonal(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
    if (ok == true) RepoHub.instance.catalog.deleteCategory(c.id);
  }
}

// ───────────── تب سرویس‌ها ─────────────
class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.services, required this.cats});
  final List<ServiceItem> services;
  final List<Category> cats;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const _EmptyState('هنوز سرویسی نیست');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        for (final s in services)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PillowCard(
              child: Row(children: [
                SmartIcon(emoji: s.emoji, imageUrl: s.imageUrl, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '🗂️ ${cats.where((c) => c.id == s.categoryId).firstOrNull?.title ?? '—'} • ${s.options.length} گزینه • ⭐ ${s.rating.toStringAsFixed(1)} (${s.ratingCount})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.6),
                    ),
                  ]),
                ),
                Switch(
                  value: s.active,
                  onChanged: (v) {
                    s.active = v;
                    RepoHub.instance.catalog.upsertService(s);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  onPressed: () => RepoHub.instance.catalog.deleteService(s.id),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(color: Color(0xFF9CA3AF))));
  }
}
