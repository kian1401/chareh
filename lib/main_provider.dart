import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/backend_config.dart';
import 'data/models.dart';
import 'firebase_options.dart';

/// نقطه‌ی ورود فلیور «چاره متخصص» — مستقیم به پرتال سرویس‌دهنده
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!BackendConfig.useMock) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(ShahrekarApp(
    initialLocation: '/p/home',
    initialPortal: UserRole.provider,
  ));
}
