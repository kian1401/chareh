import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';

/// مدیریت دسته‌بندی‌ها و سرویس‌ها (CRUD)
class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  String? _catFilter;

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت سرویس‌ها 🗂️'),
          bottom: const TabBar(tabs: [Tab(text: 'سرویس‌ها'), Tab(text: 'دسته‌بندی‌ها')]),
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tab = DefaultTabController.of(ctx);
            return AnimatedBuilder(
              animation: tab,
              builder: (_, __) => FloatingActionButton.extended(
                onPressed: () => tab.index == 0
                    ? _serviceDialog(context)
                    : _categoryDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(tab.index == 0 ? 'سرویس جدید' : 'دسته‌ی جدید'),
              ),
            );
          },
        ),
        body: TabBarView(
          children: [
            // ───────── تب سرویس‌ها ─────────
            Column(
              children: [
                SizedBox(
                  height: 46,
                  child: StreamBuilder<List<Category>>(
                    stream: repo.catalog.watchCategories(),
                    builder: (_, snap) {
                      final cats = snap.data ?? [];
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: const Text('همه'),
                              selected: _catFilter == null,
                              onSelected: (_) => setState(() => _catFilter = null),
                            ),
                          ),
                          for (final c in cats)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text('${c.emoji} ${c.title}'),
                                selected: _catFilter == c.id,
                                onSelected: (_) => setState(() => _catFilter = c.id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ServiceItem>>(
                    stream: repo.catalog.watchServices(categoryId: _catFilter),
                    builder: (_, snap) {
                      final list = snap.data ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final s = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: EmojiBadge(s.emoji, seed: s.id, size: 42),
                              title: Text(s.title,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                  '${faPrice(s.basePrice, unit: false)}+  •  ${toFaDigits(s.options.length)} پکیج  •  ⭐ ${toFaDigits(s.rating.toStringAsFixed(1))}',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'ویرایش',
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _serviceDialog(context, existing: s),
                                  ),
                                  IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        size: 20, color: AppColors.danger),
                                    onPressed: () =>
                                        RepoHub.instance.catalog.deleteService(s.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // ───────── تب دسته‌ها ─────────
            StreamBuilder<List<Category>>(
              stream: repo.catalog.watchCategories(),
              builder: (_, snap) {
                final cats = snap.data ?? [];
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 110,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10),
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    return Card(
                      child: InkWell(
                        onTap: () => _categoryDialog(context, existing: c),
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EmojiBadge(c.emoji, seed: c.id, size: 44),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(c.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 2,
                              left: 2,
                              child: IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.close_rounded,
                                    size: 17, color: AppColors.danger),
                                onPressed: () =>
                                    RepoHub.instance.catalog.deleteCategory(c.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _categoryDialog(BuildContext context, {Category? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '✨');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'دسته‌ی جدید' : 'ویرایش دسته'),
        content: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'عنوان دسته'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: emojiCtrl,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'ایموجی'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final c = existing ?? Category(
                  id: 'c${DateTime.now().millisecondsSinceEpoch}',
                  title: '',
                  emoji: '');
              c.title = titleCtrl.text.trim();
              c.emoji = emojiCtrl.text.trim().isEmpty ? '✨' : emojiCtrl.text.trim();
              RepoHub.instance.catalog.upsertCategory(c);
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _serviceDialog(BuildContext context, {ServiceItem? existing}) async {
    final cats = RepoHub.instance.catalog.watchCategories();
    final catsList = await cats.first;
    if (!context.mounted) return;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final priceCtrl =
        TextEditingController(text: existing != null ? existing.basePrice.toString() : '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '🔧');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String catId = existing?.categoryId ?? catsList.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existing == null ? 'سرویس جدید' : 'ویرایش سرویس'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'عنوان سرویس'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: emojiCtrl,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: 'ایموجی'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: catId,
                  decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                  items: [
                    for (final c in catsList)
                      DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.title}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setD(() => catId = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'قیمت پایه (تومان)', hintText: 'مثلاً ۴۵۰۰۰۰'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'توضیحات'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            FilledButton(
              onPressed: () {
                final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                if (titleCtrl.text.trim().isEmpty || price <= 0) return;
                final s = existing ??
                    ServiceItem(
                      id: 's${DateTime.now().millisecondsSinceEpoch}',
                      categoryId: catId,
                      title: '',
                      description: '',
                      emoji: '🔧',
                      basePrice: 0,
                      options: [
                        ServiceOption(
                            id: 'o0', title: 'تعرفه‌ی پایه', price: price),
                      ],
                    );
                s.title = titleCtrl.text.trim();
                s.emoji = emojiCtrl.text.trim().isEmpty ? '🔧' : emojiCtrl.text.trim();
                s.categoryId = catId;
                s.basePrice = price;
                s.description = descCtrl.text.trim().isEmpty
                    ? 'توضیحات به‌زودی تکمیل می‌شود.'
                    : descCtrl.text.trim();
                RepoHub.instance.catalog.upsertService(s);
                Navigator.pop(ctx);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}
