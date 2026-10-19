import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int _stars = 5;
  final _reviewCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  static const _milestones = [
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.onTheWay,
    BookingStatus.inProgress,
    BookingStatus.completed,
  ];

  Future<void> _cancel(Booking b) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لغو سفارش؟'),
        content: const Text(
            'لغو تا ۲ ساعت قبل از شروع سرویس رایگان است و مبلغ به کیف پول‌تان برمی‌گردد.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بله، لغو کن'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await RepoHub.instance.bookings.cancel(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('سفارش لغو شد')));
      }
    }
  }

  Future<void> _rate(Booking b, String author) async {
    setState(() => _saving = true);
    await RepoHub.instance.bookings
        .rate(b.id, stars: _stars, text: _reviewCtrl.text.trim(), author: author);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ممنون از نظرتان! 🌟')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isProvider = auth.portal == UserRole.provider;

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات سفارش')),
      body: StreamBuilder<Booking?>(
        stream: RepoHub.instance.bookings.watchBookingById(widget.id),
        builder: (_, snap) {
          final b = snap.data;
          if (b == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          EmojiBadge(b.serviceEmoji, seed: b.serviceId, size: 54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.serviceTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900, fontSize: 15.5)),
                                const SizedBox(height: 4),
                                Text(b.optionTitle,
                                    style: const TextStyle(
                                        color: AppColors.subtext, fontSize: 12)),
                              ],
                            ),
                          ),
                          StatusChip(b.status),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoBit('⏰', '${b.dayLabel} • ${b.timeSlot}'),
                          _InfoBit('🧾', 'کد: ${toFaDigits(b.id)}'),
                          PriceLabel(b.totalPrice),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // کارت سرویس‌دهنده / مشتری
              if (b.providerName != null && !isProvider)
                Card(
                  child: ListTile(
                    leading: EmojiBadge(b.providerEmoji ?? '🧑‍🔧',
                        seed: b.providerId ?? '', size: 44),
                    title: Text(b.providerName!,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('متخصص تاییدشده‌ی چاره ✅',
                        style: TextStyle(fontSize: 11.5)),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => context.push('/chat/t_${b.id}',
                          extra: 'گفتگو با ${b.providerName}'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                      label: const Text('چت'),
                    ),
                  ),
                )
              else if (isProvider)
                Card(
                  child: ListTile(
                    leading: const EmojiBadge('🙋', size: 44),
                    title: Text(b.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(b.addressText,
                        style: const TextStyle(fontSize: 11.5, height: 1.6)),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => context.push('/chat/t_${b.id}',
                          extra: 'گفتگو با ${b.customerName}'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                      label: const Text('چت'),
                    ),
                  ),
                )
              else
                const Card(
                  child: ListTile(
                    leading: Text('⏳', style: TextStyle(fontSize: 28)),
                    title: Text('در حال یافتن متخصص…'),
                    subtitle: Text('معمولاً کمتر از چند دقیقه طول می‌کشد',
                        style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              const SizedBox(height: 12),

              // لغو / پیشروی سرویس‌دهنده
              if (!isProvider &&
                  (b.status == BookingStatus.pending || b.status == BookingStatus.accepted))
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  onPressed: () => _cancel(b),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('لغو سفارش'),
                ),
              if (isProvider && b.status.next != null)
                ElevatedButton.icon(
                  onPressed: () => RepoHub.instance.bookings.advance(b.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('رفتن به مرحله‌ی «${b.status.next!.fa}»'),
                ),
              const SizedBox(height: 12),

              // تایم‌لاین
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('وضعیت سفارش'),
                      const SizedBox(height: 14),
                      if (b.status == BookingStatus.cancelled ||
                          b.status == BookingStatus.rejected)
                        StatusChip(b.status)
                      else
                        ..._buildTimeline(b),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // اطلاعات پرداخت و آدرس
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('اطلاعات رزرو'),
                      const SizedBox(height: 10),
                      _InfoRow(Icons.location_on_outlined, b.addressText),
                      if (b.addOnTitles.isNotEmpty)
                        _InfoRow(Icons.add_circle_outline, 'افزودنی: ${b.addOnTitles.join('، ')}'),
                      _InfoRow(Icons.payment_rounded, 'پرداخت: ${b.paymentMethod}'),
                    ],
                  ),
                ),
              ),

              // امتیازدهی
              if (!isProvider && b.status == BookingStatus.completed) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: b.rating == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader('به این سرویس چه امتیازی می‌دهید؟'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 1; i <= 5; i++)
                                    IconButton(
                                      onPressed: () => setState(() => _stars = i),
                                      icon: Icon(
                                        i <= _stars
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 36,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                ],
                              ),
                              TextField(
                                controller: _reviewCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                    hintText: 'نظرتان را بنویسید (اختیاری)…'),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _rate(
                                          b, auth.user?.name ?? 'کاربر چاره'),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('ثبت امتیاز'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader('امتیاز شما'),
                              const SizedBox(height: 8),
                              RatingStars(b.rating!.toDouble(), size: 24),
                              if ((b.review ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(b.review!,
                                    style: const TextStyle(height: 1.7)),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTimeline(Booking b) {
    final events = {for (final e in b.timeline) e.status: e};
    final doneCount = _milestones.indexOf(b.status) + 1;
    final widgets = <Widget>[];

    for (var i = 0; i < _milestones.length; i++) {
      final st = _milestones[i];
      final done = i < doneCount;
      final current = i == doneCount - 1;
      final ev = events[st];

      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? (current ? st.color : AppColors.success)
                        : AppColors.border,
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: done ? 15 : 8,
                    color: Colors.white,
                  ),
                ),
                if (i < _milestones.length - 1)
                  Container(
                    width: 2,
                    height: 34,
                    color: i < doneCount - 1 ? AppColors.success : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(st.fa,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: done ? AppColors.text : AppColors.subtext,
                        )),
                    if (ev != null)
                      Text(timeAgoFa(ev.at),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.subtext)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return widgets;
  }
}

class _InfoBit extends StatelessWidget {
  const _InfoBit(this.icon, this.text);
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.subtext)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.subtext),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.7))),
        ],
      ),
    );
  }
}
