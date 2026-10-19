import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سفارش‌های من'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'جاری'),
              Tab(text: 'گذشته'),
            ],
          ),
        ),
        body: !auth.loggedIn || auth.user!.role != UserRole.customer
            ? EmptyState(
                emoji: '🔐',
                title: 'برای دیدن سفارش‌ها وارد شوید',
                body: 'با ورود، تاریخچه‌ی سفارش و وضعیت زنده‌ی آن‌ها را می‌بینید',
                actionText: 'ورود / ثبت‌نام',
                onAction: () => context.push('/auth'),
              )
            : StreamBuilder<List<Booking>>(
                stream: RepoHub.instance.bookings
                    .watchCustomerBookings(auth.user!.id),
                builder: (_, snap) {
                  final all = snap.data ?? [];
                  final current = all.where((b) => b.status.isActive).toList();
                  final past = all.where((b) => !b.status.isActive).toList();
                  return TabBarView(
                    children: [
                      _BookingList(bookings: current, emptyEmoji: '📭', emptyText: 'سفارش جاری ندارید\nاز صفحه‌ی اصلی یک سرویس رزرو کنید'),
                      _BookingList(bookings: past, emptyEmoji: '🧾', emptyText: 'هنوز سفارشی ثبت نکرده‌اید'),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyEmoji,
    required this.emptyText,
  });

  final List<Booking> bookings;
  final String emptyEmoji;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(emoji: emptyEmoji, title: 'خالی است', body: emptyText);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => BookingCard(
        booking: bookings[i],
        onTap: () => context.push('/order/${bookings[i].id}'),
        footer: bookings[i].status == BookingStatus.completed && bookings[i].rating == null
            ? SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/order/${bookings[i].id}'),
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('امتیاز و نظر'),
                ),
              )
            : null,
      ),
    );
  }
}
