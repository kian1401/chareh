import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';

/// فهرست سرویس‌ها با جستجو و فیلتر دسته‌بندی
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.initialCategory, this.initialQuery});

  final String? initialCategory;
  final String? initialQuery; // 'focus=1' برای باز شدن کیبورد

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _queryCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.context != null &&
          GoRouterState.of(context).uri.queryParameters['focus'] == '1') {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _categoryId = widget.initialCategory;
    }
    if (GoRouterState.of(context).uri.queryParameters['focus'] == '1') {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _queryCtrl,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'جستجو در سرویس‌ها…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _queryCtrl.clear();
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              height: 46,
              child: StreamBuilder<List<Category>>(
                stream: repo.catalog.watchCategories(),
                builder: (_, snap) {
                  final cats = snap.data ?? [];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('همه'),
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                      ),
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('${c.emoji} ${c.title}'),
                            selected: _categoryId == c.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = c.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ServiceItem>>(
                stream: repo.catalog.watchServices(
                  categoryId: _categoryId,
                  query: _queryCtrl.text,
                ),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = (snap.data ?? []).where((s) => s.active).toList();
                  if (list.isEmpty) {
                    return const EmptyState(
                      emoji: '🔍',
                      title: 'چیزی پیدا نشد',
                      body: 'عبارت دیگری را جستجو کنید یا دسته‌بندی را عوض کنید',
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 205,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => ServiceCard(
                      service: list[i],
                      onTap: () => context.push('/service/${list[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
