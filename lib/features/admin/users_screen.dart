import 'package:flutter/material.dart';

import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';

/// 👥 کاربران واقعی سامانه (هر شماره = یک حساب که خودشان با OTP ساخته‌اند)
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کاربران سامانه')),
      body: StreamBuilder<AppSettings>(
        stream: RepoHub.instance.misc.watchSettings(),
        builder: (_, __) => _UsersList(),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProviderProfile>>(
      stream: RepoHub.instance.providers.watchAll(),
      builder: (_, proSnap) {
        final providers = proSnap.data ?? [];
        // همه آمار کاربران از روی سفارش‌ها و ثبت‌نام‌ها قابل استخراج است
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PillowCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('👥 رجیستری کاربران', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text(
                  'هر شماره‌ای که با OTP وارد شود، یک حساب واقعی دائمی می‌سازد (هیچ کاربر جعلی‌ای در سیستم نیست). متخصصان هم توسط شما از تب «متخصصان» تعریف می‌شوند.',
                  style: TextStyle(fontSize: 12, height: 1.8, color: Color(0xFF6B7280)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SectionTitle('🧑‍🔧 متخصصان فعال روی سیستم (${toFaDigits(providers.length)})'),
            if (providers.isEmpty) const Padding(
              padding: EdgeInsets.all(16),
              child: Text('هنوز متخصصی نیست — از تب متخصصان اضافه کنید.', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            for (final p in providers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PillowCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    SmartIcon(emoji: p.emoji, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${p.phone} • ${p.skills.take(2).join('، ')}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ]),
                    ),
                    Text(toFaDigits(p.phone.substring(0, 11)),
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                  ]),
                ),
              ),
            const SizedBox(height: 16),
            const SectionTitle('📊 آمار کاربران'),
            _StatGrid(providers: providers),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.providers});
  final List<ProviderProfile> providers;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: RepoHub.instance.bookings.watchAll(),
      builder: (_, bSnap) {
        final bookings = bSnap.data ?? [];
        final customers = bookings.map((b) => b.customerId).toSet().length;
        return AdaptiveGrid(
          count: 4,
          ratio: 1.7,
          item: (i) => _stat(i, customers, bookings),
        );
      },
    );
  }

  Widget _stat(int i, int customers, List<Booking> bookings) {
    final items = [
      ('مشتریان فعال', toFaDigits(customers), '🙋'),
      ('متخصصان', toFaDigits(providers.length), '🧑‍🔧'),
      ('سفارش‌های کل', toFaDigits(bookings.length), '📦'),
      ('سفارش تکمیل‌شده', toFaDigits(bookings.where((b) => b.status == BookingStatus.completed).length), '✅'),
    ];
    final x = items[i];
    return PillowCard(
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(x.$3, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(x.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        Text(x.$1, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
      ]),
    );
  }
}
