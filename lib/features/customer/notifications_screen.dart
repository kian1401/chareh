import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthState>();
      RepoHub.instance.misc.markAllRead(auth.user?.id ?? 'u_c1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final userId = auth.user?.id ?? 'u_c1';

    return Scaffold(
      appBar: AppBar(title: const Text('اعلان‌ها')),
      body: StreamBuilder<List<AppNotification>>(
        stream: RepoHub.instance.misc.watchNotifications(userId),
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '🔕',
              title: 'اعلانی ندارید',
              body: 'خبرهای جدید اینجا نمایش داده می‌شود',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .08),
                    child: Text(n.emoji),
                  ),
                  title: Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    n.body,
                    style: const TextStyle(fontSize: 12, height: 1.6),
                  ),
                  trailing: Text(
                    timeAgoFa(n.at),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.subtext,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
