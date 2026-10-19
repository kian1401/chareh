import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';

/// 🏙️ فعال‌سازی سفارش در شهرهای بزرگ — فعلاً فقط ارومیه روشن است
class AdminCitiesScreen extends StatelessWidget {
  const AdminCitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شهرهای فعال چاره')),
      body: StreamBuilder<List<City>>(
        stream: RepoHub.instance.catalog.watchCities(activeOnly: false),
        builder: (_, snap) {
          final cities = snap.data ?? [];
          final activeCount = cities.where((c) => c.active).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '🟢 $activeCount شهر فعال — شروع آزمایشی در «ارومیه». با فعال کردن هر شهر، کاربرانِ همان شهر سفارش می‌گذارند و متخصصان‌اش نمایان می‌شوند.',
                    style: const TextStyle(fontSize: 12.5, height: 1.8),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  children: [
                    for (final c in cities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PillowCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Row(children: [
                            Text(c.active ? '🟢' : '⚪', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                Text(c.province, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              ]),
                            ),
                            Switch(
                              value: c.active,
                              onChanged: (v) {
                                c.active = v;
                                RepoHub.instance.catalog.upsertCity(c);
                              },
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCity(context),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('افزودن شهر'),
      ),
    );
  }

  void _addCity(BuildContext context) {
    final nameCtrl = TextEditingController();
    final provCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('افزودن شهر'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام شهر')),
          TextField(controller: provCtrl, decoration: const InputDecoration(labelText: 'استان')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              await RepoHub.instance.catalog.upsertCity(City(
                id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                title: name,
                province: provCtrl.text.trim(),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('افزودن (غیرفعال پیش‌فرض)'),
          ),
        ],
      ),
    );
  }
}
