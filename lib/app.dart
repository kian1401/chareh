import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_state.dart';
import 'data/models.dart';
import 'features/auth/auth_state.dart';

class CharehApp extends StatelessWidget {
  CharehApp({super.key, this.initialLocation = '/start', this.initialPortal})
    : router = buildRouter(initialLocation);

  /// نقطه‌ی شروع: '/start' (انتخاب پرتال) یا مستقیم به یک پرتال (فلیورها)
  final String initialLocation;

  /// اگر ست شود، اپ روی همان پرتال قفل می‌شود (برای فلیورهای جداگانه)
  final UserRole? initialPortal;

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(initialPortal: initialPortal),
      child: ChangeNotifierProvider(
        create: (_) => ThemeState(),
        child: Consumer<ThemeState>(
          builder: (_, t, __) => MaterialApp.router(
            title: '${t.appTitle} — خدمت از در خانه شما',
            debugShowCheckedModeBanner: false,
            theme: t.light,
            locale: const Locale('fa'),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      ),
    );
  }
}
