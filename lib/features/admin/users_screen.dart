import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/mock/mock_database.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';

/// مدیریت متخصصین (تایید/تعلیق) و مشتریان
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepoHub.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('کاربران و متخصصین 👥')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('متخصصین (سرویس‌دهندگان)'),
          const SizedBox(height: 8),
          StreamBuilder<List<ProviderProfile>>(
            stream: repo.catalog.watchProviders(),
            builder: (_, snap) {
              final list = snap.data ?? [];
              return Column(
                children: [
                  for (final p in list)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: EmojiBadge(p.emoji, seed: p.id, size: 44),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13.5)),
                            ),
                            if (p.level == 'برتر') ...[
                              const SizedBox(width: 4),
                              const Text('⭐', style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                        subtitle: Text(
                            '${p.skills.take(2).join('، ')} • ⭐ ${toFaDigits(p.rating.toStringAsFixed(1))} • ${toFaDigits(p.jobsDone)} کار',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 28,
                              child: Switch(
                                value: p.verified,
                                onChanged: (v) =>
                                    RepoHub.instance.providers.setVerified(p.id, v),
                              ),
                            ),
                            Text(p.verified ? 'تاییدشده' : 'معلق',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    color: p.verified
                                        ? AppColors.success
                                        : AppColors.danger)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const SectionHeader('مشتریان'),
          const SizedBox(height: 8),
          if (repo.isMock)
            for (final u in MockDb()
                .demoUsers
                .values
                .where((u) => u.role == UserRole.customer))
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: EmojiBadge(u.avatarEmoji, seed: u.id, size: 42),
                  title: Text(u.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text(toFaDigits(u.phone),
                      style: const TextStyle(fontSize: 11.5)),
                  trailing: Text('کیف پول: ${faPrice(u.walletBalance, unit: false)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.subtext)),
                ),
              )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'در حالت Firebase فهرست مشتریان از کالکشن users خوانده می‌شود (نمایش در نسخه‌ی بعدی پنل).',
                    style: TextStyle(fontSize: 12, height: 1.7)),
              ),
            ),
        ],
      ),
    );
  }
}
