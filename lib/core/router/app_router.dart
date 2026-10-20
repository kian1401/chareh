import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../features/admin/bookings_screen.dart';
import '../../features/admin/dashboard_screen.dart';
import '../../features/admin/services_screen.dart';
import '../../features/admin/users_screen.dart';
import '../../features/admin/providers_screen.dart';
import '../../features/admin/cities_screen.dart';
import '../../features/admin/settings_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/customer/assistant_screen.dart';
import '../../features/customer/booking_flow_screen.dart';
import '../../features/customer/home_screen.dart';
import '../../features/customer/notifications_screen.dart';
import '../../features/customer/order_detail_screen.dart';
import '../../features/customer/orders_screen.dart';
import '../../features/customer/profile_screen.dart';
import '../../features/customer/service_detail_screen.dart';
import '../../features/customer/services_screen.dart';
import '../../features/provider/dashboard_screen.dart' as provider;
import '../../features/provider/earnings_screen.dart';
import '../../features/provider/jobs_screen.dart';
import '../../features/provider/profile_screen.dart' as provider;
import '../../features/provider/requests_screen.dart';
import '../../features/shared/chat_screen.dart';
import '../../features/shared/shells.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter([String initialLocation = '/start']) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    routes: [
      // 🩹 ریشه: بدون این، go('/') و صفحهٔ خطای go_router («Go to homepage») کرش می‌کردند
      GoRoute(path: '/', redirect: (_, __) => '/start'),
      GoRoute(path: '/start', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),

      // مسیرهای روی‌هم‌گذار (خارج از شل تب‌ها)
      GoRoute(
        path: '/service/:id',
        builder: (_, s) => ServiceDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book',
        builder: (_, s) => BookingFlowScreen(draft: s.extra! as BookingDraft),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatScreen(
          threadId: s.pathParameters['id']!,
          title: (s.extra as String?) ?? 'گفتگو',
          peerEmoji: '🧑‍🔧',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ─────────── پرتال مشتری ───────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/home',
                builder: (_, __) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/services',
                builder: (_, s) => ServicesScreen(
                  initialCategory: s.uri.queryParameters['cat'],
                  initialQuery: s.uri.queryParameters['q'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/orders',
                builder: (_, __) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/assistant',
                builder: (_, __) => const AssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/profile',
                builder: (_, __) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─────────── پرتال سرویس‌دهنده ───────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ProviderShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/home',
                builder: (_, __) => const provider.ProviderDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/requests',
                builder: (_, __) => const RequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/p/jobs', builder: (_, __) => const JobsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/earnings',
                builder: (_, __) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/ai',
                builder: (_, __) => const provider.AiHelperScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/profile',
                builder: (_, __) => const provider.ProviderProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─────────── پرتال ادمین ───────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/home',
                builder: (_, __) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/services',
                builder: (_, __) => const AdminServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/providers',
                builder: (_, __) => const AdminProvidersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/cities',
                builder: (_, __) => const AdminCitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/bookings',
                builder: (_, __) => const AdminBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/users',
                builder: (_, __) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/settings',
                builder: (_, __) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
