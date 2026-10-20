import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/backend_config.dart';
import 'data/models.dart';
import 'firebase_options.dart';

/// نقطه‌ی ورود فلیور «چاره» — مستقیم به پرتال مشتری
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!BackendConfig.useMock) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(
    CharehApp(initialLocation: '/c/home', initialPortal: UserRole.customer),
  );
}
