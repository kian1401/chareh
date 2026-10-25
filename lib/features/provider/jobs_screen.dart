import '../../core/utils/persian_utils.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

/// کارهای پذیرفته‌شده‌ی متخصص (جاری + تاریخچه)
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.effectiveProviderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('کارها')),
        body: const EmptyState(
          emoji: '🔐',
          title: 'ابتدا به‌عنوان سرویس‌دهنده وارد شوید',
        ),
      );
    }
    final pid = auth.effectiveProviderId!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کارهای من 🛠️'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'جاری'),
              Tab(text: 'تکمیل‌شده'),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: RepoHub.instance.bookings.watchProviderJobs(pid),
          builder: (_, snap) {
            final all = snap.data ?? [];
            final active = all.where((b) => b.status.isActive).toList();
            final done = all
                .where((b) => b.status == BookingStatus.completed)
                .toList();
            return TabBarView(
              children: [
                _JobsList(bookings: active, active: true),
                _JobsList(bookings: done, active: false),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({required this.bookings, required this.active});
  final List<Booking> bookings;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        emoji: active ? '🛠️' : '✅',
        title: active ? 'کاری در جریان نیست' : 'هنوز کاری تکمیل نشده',
        body: active ? 'از تب «درخواست‌ها» سفارش جدید بپذیرید' : null,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        final next = b.status.next;
        return BookingCard(
          booking: b,
          onTap: () => context.push('/order/${b.id}'),
          footer: active
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 ${toFaDigits(b.addressText)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (next != null)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  RepoHub.instance.bookings.advance(b.id),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                '«${next.fa}»',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        else
                          const Spacer(flex: 2),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => context.push(
                            '/chat/t_${b.id}',
                            extra: 'گفتگو با ${b.customerName}',
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      b.rating != null
                          ? 'امتیاز مشتری: ${b.rating} از ۵'
                          : 'بدون امتیاز',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if ((b.review ?? '').isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '«${b.review!}»',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
