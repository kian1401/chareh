import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        (Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, 'داشبورد'),
        (Icons.inbox_rounded, Icons.inbox_outlined, 'درخواست‌ها'),
        (Icons.handyman_rounded, Icons.handyman_outlined, 'کارها'),
        (Icons.psychology_rounded, Icons.psychology_outlined, 'دستیار AI'),
        (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'درآمد'),
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
    return _Shell(
      shell: shell,
      items: const [
        (Icons.dashboard_rounded, Icons.dashboard_outlined, 'داشبورد'),
        (Icons.category_rounded, Icons.category_outlined, 'دسته‌ها'),
        (Icons.group_work_rounded, Icons.group_work_outlined, 'متخصصان'),
        (Icons.location_city_rounded, Icons.location_city_outlined, 'شهرها'),
        (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'سفارش‌ها'),
        (Icons.group_rounded, Icons.group_outlined, 'کاربران'),
        (Icons.tune_rounded, Icons.tune_outlined, 'تنظیمات'),
      ],
    );
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
