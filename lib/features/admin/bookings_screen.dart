import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('همه‌ی رزروها 🧾')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('همه'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final s in BookingStatus.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(s.fa),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: RepoHub.instance.bookings.watchAll(),
              builder: (_, snap) {
                var list = snap.data ?? [];
                if (_filter != null) {
                  list = list.where((b) => b.status == _filter).toList();
                }
                if (list.isEmpty) {
                  return const EmptyState(
                      emoji: '🧾', title: 'رزرویی با این فیلتر نیست');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final b = list[i];
                    return BookingCard(
                      booking: b,
                      footer: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '👤 ${b.customerName}${b.providerName != null ? '  •  🧑‍🔧 ${b.providerName}' : ''}  •  ${timeAgoFa(b.createdAt)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.subtext),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<BookingStatus>(
                            tooltip: 'تغییر وضعیت',
                            icon: const Icon(Icons.more_vert_rounded, size: 20),
                            onSelected: (s) => RepoHub.instance.bookings
                                .updateStatus(b.id, s, note: 'ویرایش توسط ادمین'),
                            itemBuilder: (_) => [
                              for (final s in BookingStatus.values)
                                PopupMenuItem(
                                  value: s,
                                  child: Text(s.fa,
                                      style: const TextStyle(fontSize: 13)),
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
          ),
        ],
      ),
    );
  }
}
