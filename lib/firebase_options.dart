// lib/firebase_options.dart
//
// QUAN TRỌNG: File này là placeholder.
// Chạy lệnh sau để sinh file thật sau khi tạo Firebase project:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// File thật sẽ chứa các API key và config cho từng platform.

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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Thay các giá trị dưới đây bằng giá trị thật từ Firebase Console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLKmcdzPM80_voAcNxE5lESuKmHgFfWJI',
    appId: '1:671985858494:android:ee1905e27eaf1d7ef2ebef',
    messagingSenderId: '671985858494',
    projectId: 'quanlygas-ae3f6',
    storageBucket: 'quanlygas-ae3f6.firebasestorage.app',
  );

  // sau khi chạy `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAnyP8UDBMV90Vasf5CC-MO8LJxkA7s4XI',
    appId: '1:671985858494:ios:676e41edafcffcd4f2ebef',
    messagingSenderId: '671985858494',
    projectId: 'quanlygas-ae3f6',
    storageBucket: 'quanlygas-ae3f6.firebasestorage.app',
    iosBundleId: 'com.quanlygasapp.quanLyGasApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );
}