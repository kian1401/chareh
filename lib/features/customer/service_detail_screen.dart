import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _optIndex = 0;
  final Set<String> _addOns = {};

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;
    final auth = context.watch<AuthState>();

    return StreamBuilder<ServiceItem?>(
      stream: repo.catalog.watchService(widget.id),
      builder: (_, snap) {
        final s = snap.data;
        if (snap.connectionState == ConnectionState.waiting && s == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (s == null) {
          return const Scaffold(
            body: EmptyState(emoji: '😕', title: 'سرویس پیدا نشد'),
          );
        }
        final options = s.options.isNotEmpty
            ? s.options
            : [
                ServiceOption(
                  id: 'o0',
                  title: 'تعرفه‌ی پایه',
                  price: s.basePrice,
                ),
              ];
        if (_optIndex >= options.length) _optIndex = 0;
        final selected = options[_optIndex];
        var total = selected.price;
        for (final a in s.addOns) {
          if (_addOns.contains(a.id)) total += a.price;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(s.title),
            actions: [
              IconButton(
                tooltip: 'علاقه‌مندی',
                onPressed: () {
                  if (!auth.loggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('برای علاقه‌مندی‌ها ابتدا وارد شوید'),
                      ),
                    );
                    return;
                  }
                  auth.toggleFavorite(s.id);
                },
                icon: Icon(
                  auth.isFavorite(s.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: auth.isFavorite(s.id) ? AppColors.danger : null,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientFor(s.id),
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Center(
                  child: Text(s.emoji, style: const TextStyle(fontSize: 72)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        PriceLabel(s.basePrice, fromPrefix: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingStars(s.rating, showValue: true),
                        const SizedBox(width: 6),
                        Text(
                          '(${toFaDigits(s.ratingCount)} نظر)',
                          style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${toFaDigits(s.jobsDone)} سرویس انجام‌شده',
                          style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (s.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final t in s.tags)
                            Chip(
                              label: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      s.description,
                      style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 13.5,
                        height: 1.9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ضمانت بازگشت وجه در صورت نارضایتی • متخصص تاییدشده و بیمه',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const SectionHeader('گزینه‌های سرویس'),
                    const SizedBox(height: 12),
                    for (var i = 0; i < options.length; i++) ...[
                      _OptionCard(
                        option: options[i],
                        selected: i == _optIndex,
                        onTap: () => setState(() => _optIndex = i),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (s.addOns.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionHeader('خدمات افزودنی'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in s.addOns)
                            FilterChip(
                              selected: _addOns.contains(a.id),
                              onSelected: (v) => setState(
                                () => v
                                    ? _addOns.add(a.id)
                                    : _addOns.remove(a.id),
                              ),
                              label: Text(
                                '${a.title} (+${faPrice(a.price)})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    const SectionHeader('نظرات کاربران'),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Review>>(
                      stream: repo.catalog.watchReviews(s.id),
                      builder: (_, snap) {
                        final reviews = snap.data ?? [];
                        return Column(
                          children: [
                            for (final r in reviews)
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 14,
                                            child: Icon(Icons.person, size: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              r.author,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                          RatingStars(r.rating, size: 12),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        r.text,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          height: 1.7,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.dateLabel,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.subtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مبلغ قابل پرداخت',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.subtext,
                        ),
                      ),
                      PriceLabel(total, big: true),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final draft = BookingDraft()..reset(s);
                        draft.option = selected;
                        draft.addOnIds.addAll(_addOns);
                        context.push('/book', extra: draft);
                      },
                      icon: const Icon(Icons.event_available_rounded),
                      label: const Text('انتخاب زمان و ادامه'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ServiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: .06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.subtext,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (option.duration.isNotEmpty)
                    Text(
                      '⏱ ${option.duration}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtext,
                      ),
                    ),
                ],
              ),
            ),
            PriceLabel(option.price),
          ],
        ),
      ),
    );
  }
}
