// ⚠️ فایل جایگزین — پس از اجرای `flutterfire configure` با مقادیر واقعی پروژه‌ی شما جایگزین می‌شود.
// این مقادیر ساختگی فقط برای کامپایل شدن پروژه در حالت «آماده‌ی Firebase» هستند.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // TODO: اجرای flutterfire configure — این مقادیر را با خروجی واقعی عوض کنید
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'chareh-demo',
    authDomain: 'chareh-demo.firebaseapp.com',
    storageBucket: 'chareh-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'chareh-demo',
    storageBucket: 'chareh-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'chareh-demo',
    storageBucket: 'chareh-demo.appspot.com',
    iosBundleId: 'com.chareh.app',
  );
}
