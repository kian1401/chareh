import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/ui.dart';
import '../auth/auth_state.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      shell: shell,
      items: const [
        (Icons.home_rounded, Icons.home_outlined, 'خانه'),
        (Icons.grid_view_rounded, Icons.grid_view_outlined, 'سرویس‌ها'),
        (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'سفارش‌ها'),
        (Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'دستیار'),
        (Icons.person_rounded, Icons.person_outline_rounded, 'پروفایل'),
      ],
    );
  }
}

class ProviderShell extends StatelessWidget {
  const ProviderShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      shell: shell,
      items: const [
        (
          Icons.space_dashboard_rounded,
          Icons.space_dashboard_outlined,
          'داشبورد',
        ),
        (Icons.inbox_rounded, Icons.inbox_outlined, 'درخواست‌ها'),
        (Icons.handyman_rounded, Icons.handyman_outlined, 'کارها'),
        (
          Icons.account_balance_wallet_rounded,
          Icons.account_balance_wallet_outlined,
          'درآمد',
        ),
        (Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'هوش 🤖'),
        (Icons.person_rounded, Icons.person_outline_rounded, 'پروفایل'),
      ],
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined, 'داشبورد'),
      (Icons.category_rounded, Icons.category_outlined, 'سرویس‌ها'),
      (Icons.engineering_rounded, Icons.engineering_outlined, 'متخصصان'),
      (Icons.location_city_rounded, Icons.location_city_outlined, 'شهرها'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'رزروها'),
      (Icons.group_rounded, Icons.group_outlined, 'کاربران'),
      (Icons.tune_rounded, Icons.tune_outlined, 'تنظیمات'),
    ];
    // 🔒 گارد سراسری پنل مدیریت: بدون نقش ادمین هیچ‌کدام از زیرصفحه‌ها (رزروها/سرویس‌ها/کاربران/تنظیمات) داده نشان نمی‌دهند
    if (!context.watch<AuthState>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('پنل مدیریت')),
        body: const NeedLogin(
          emoji: '🛡️',
          title: 'به‌عنوان مدیر وارد شوید',
          hint: 'پنل مدیریت فقط برای مدیر ارشد و مدیران مجاز است — با شمارهٔ خود وارد شوید',
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final (active, idle, label) in items)
              NavigationDestination(
                icon: Icon(idle),
                selectedIcon: Icon(active),
                label: label,
              ),
          ],
        ),
      );
    }
    return _Shell(shell: shell, items: items);
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final (active, idle, label) in items)
            NavigationDestination(
              icon: Icon(idle),
              selectedIcon: Icon(active),
              label: label,
            ),
        ],
      ),
    );
  }
}
