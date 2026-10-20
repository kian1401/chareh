import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/backend_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🪲 رویداد خطا در بیلد وب (برای دیباگ تست E2E — print در وب به کنسول مرورگر می‌رود)
  FlutterError.onError = (d) {
    // ignore: avoid_print
    print('FLUTTERERROR ▶ ${d.exceptionAsString()}\n${d.stack}');
  };
  ui.PlatformDispatcher.instance.onError = (e, s) {
    // ignore: avoid_print
    print('ZONEFATAL ▶ $e\n$s');
    return true;
  };
  assert(() {
    FlutterError.onError = FlutterError.dumpErrorToConsole;
    return true;
  }());
  if (!BackendConfig.useMock) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(CharehApp());
}
