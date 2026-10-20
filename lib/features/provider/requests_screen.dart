import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 📥 درخواست‌های باز بازار برای متخصص (همان شهر)
/// متخصص از میان روزها/بازه‌های پیشنهادی مشتری، بهترین را «قطعی» می‌کند
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.loggedIn || auth.effectiveProviderId == null) {
      return Scaffold(
        body: const NeedLogin(
          emoji: '🧑‍🔧',
          title: 'حساب متخصص لازم است',
          hint: 'اگر متخصص هستی، ادمین شهرت را اضافه می‌کند. وگرنه از بخش «تماس با ما» درخواستت را بفرست.',
        ),
      );
    }
    return StreamBuilder<ProviderProfile?>(
      stream: RepoHub.instance.providers.watchProfile(
        auth.effectiveProviderId!,
      ),
      builder: (_, prof) {
        final city = prof.data?.cityId ?? 'urmia';
        return StreamBuilder<List<Booking>>(
          stream: RepoHub.instance.bookings.watchProviderRequests(city),
          builder: (_, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const _Empty();
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final b in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(booking: b, provider: prof.data!),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('🌴', style: TextStyle(fontSize: 56)),
          SizedBox(height: 10),
          Text(
            'الان درخواست بازی نیست!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            'ورود جدید، اینجا لحظه‌ای و هم‌به‌زودی پدیدار می‌شود 🔔',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking, required this.provider});
  final Booking booking;
  final ProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return PillowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SmartIcon(emoji: b.serviceEmoji, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.serviceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      b.optionTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${b.customerName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (b.candidateDays.isNotEmpty) ...[
            const Text(
              '🗓️ روزهای پیشنهادی مشتری:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final day in b.candidateDays)
                  Chip(label: Text(day, style: const TextStyle(fontSize: 11))),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (b.candidateSlots.isNotEmpty) ...[
            const Text(
              '⏰ بازه‌های پیشنهادی:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slot in b.candidateSlots)
                  Chip(label: Text(slot, style: const TextStyle(fontSize: 11))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            b.maskedContact(true),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
          ),
          Text(
            '📍 ${b.addressText}',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
              height: 1.6,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _acceptSheet(context, b),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('پذیرش + انتخاب زمان'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => RepoHub.instance.bookings.reject(b.id),
                child: const Text('رد'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⏰ انتخاب یکی از ترکیب‌های پیشنهادی مشتری به‌عنوان زمان نهایی
  void _acceptSheet(BuildContext context, Booking b) {
    String day = b.candidateDays.firstWhere(
      (_) => true,
      orElse: () => b.dayLabel,
    );
    String slot = b.candidateSlots.firstWhere(
      (_) => true,
      orElse: () => b.timeSlot,
    );
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setIn) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'کدام زمان را قطعی می‌کنی؟',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'روز:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d
                      in (b.candidateDays.isNotEmpty
                          ? b.candidateDays
                          : [b.dayLabel]))
                    ChoiceChip(
                      label: Text(d),
                      selected: day == d,
                      onSelected: (_) => setIn(() => day = d),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'ساعت:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s
                      in (b.candidateSlots.isNotEmpty
                          ? b.candidateSlots
                          : [b.timeSlot]))
                    ChoiceChip(
                      label: Text(s),
                      selected: slot == s,
                      onSelected: (_) => setIn(() => slot = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await RepoHub.instance.bookings.accept(
                    b.id,
                    provider,
                    day: day,
                    slot: slot,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ برای $day $slot رزرو شد و به مشتری اعلام زدم',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('تأیید و شروع هماهنگی'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
