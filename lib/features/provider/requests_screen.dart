import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

/// درخواست‌های باز بازار — سفارش‌های منتظرِ پذیرش
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Future<void> _accept(BuildContext context, Booking b) async {
    final auth = context.read<AuthState>();
    final pid = auth.linkedProviderId!;
    final p = await RepoHub.instance.providers.watchProfile(pid).first;
    if (p == null) return;
    await RepoHub.instance.bookings.accept(b.id, p);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('سفارش پذیرفته شد ✅ به تب «کارها» اضافه شد')));
    }
  }

  Future<void> _reject(BuildContext context, Booking b) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رد درخواست'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              hintText: 'دلیل رد (اختیاری)…', labelText: 'دلیل'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('رد کن'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await RepoHub.instance.bookings.reject(b.id, reason: reasonCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.user?.role != UserRole.provider) {
      return Scaffold(
        appBar: AppBar(title: const Text('درخواست‌ها')),
        body: const EmptyState(emoji: '🔐', title: 'ابتدا به‌عنوان سرویس‌دهنده وارد شوید'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('درخواست‌های جدید 📥'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('سفارش‌های باز بازار، مرتب‌شده بر اساس نزدیکی و مهارت شما',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: RepoHub.instance.bookings.watchProviderRequests(),
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '📭',
              title: 'درخواست جدیدی نیست',
              body: 'به‌محض ثبت سفارش جدید توسط مشتری‌ها، اینجا نمایش داده می‌شود',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final b = list[i];
              return BookingCard(
                booking: b,
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 ${b.addressText}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.subtext, height: 1.6)),
                    const SizedBox(height: 6),
                    Text('سفارش‌دهنده: ${b.customerName} • ${timeAgoFa(b.createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.subtext)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _accept(context, b),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('پذیرش سفارش'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger)),
                            onPressed: () => _reject(context, b),
                            child: const Text('رد'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
