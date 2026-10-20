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
            const SectionTitle('🔐 مدیران سیستم'),
            const _AdminsSection(),
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

/// 🔐 فهرست مدیران — فقط مدیر ارشد (۰۹۱۴۸۰۰۲۴۶۱) می‌تواند دیگران را اضافه/حذف کند
class _AdminsSection extends StatelessWidget {
  const _AdminsSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: RepoHub.instance.misc.watchAdminPhones(),
      builder: (_, snap) {
        final admins = snap.data ?? const ['09148002461'];
        return PillowCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'ورود به پنل مدیریت فقط برای شماره‌های این فهرست باز است. شمارهٔ ارشد قابل‌حذف نیست و بقیهٔ مدیران را او ثبت می‌کند.',
              style: TextStyle(fontSize: 11.5, height: 1.8, color: Color(0xFF6B7280)),
            ),
            const Divider(height: 18),
            for (final phone in admins)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(
                    phone == '09148002461' ? Icons.verified_user_rounded : Icons.admin_panel_settings_outlined,
                    color: phone == '09148002461' ? const Color(0xFF6D28D9) : Colors.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(toFaDigits(phone),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1)),
                      Text(phone == '09148002461' ? 'مدیر ارشد 👑' : 'مدیر',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
                  ),
                  if (phone != '09148002461')
                    IconButton(
                      tooltip: 'حذف دسترسی',
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: () async {
                        await RepoHub.instance.misc.removeAdminPhone(phone);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('🗑️ دسترسی مدیر حذف شد')));
                        }
                      },
                    )
                  else
                    const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                ]),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _addAdminDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('ثبت مدیر جدید'),
              ),
            ),
          ]),
        );
      },
    );
  }

  static void _addAdminDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeSheet(
        title: const Text('➕ ثبت مدیر جدید'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'شماره موبایل مدیر جدید را وارد کنید؛ از این به بعد می‌تواند وارد پنل مدیریت شود.',
            style: TextStyle(fontSize: 12, height: 1.8),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '09123456789',
              counterText: '',
              prefixIcon: Icon(Icons.phone_android_rounded),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () async {
              final phone = ctrl.text.trim();
              if (phone.length != 11 || !phone.startsWith('09')) return;
              await RepoHub.instance.misc.addAdminPhone(phone);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ مدیر جدید ثبت شد — حالا می‌تواند وارد شود')));
              }
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }
}
