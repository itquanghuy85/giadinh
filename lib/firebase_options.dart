// File generated manually from existing Firebase project config.
// Web appId: lấy từ Firebase Console → Project Settings → Your apps → Web app → App ID
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Nền tảng này chưa được cấu hình Firebase.');
    }
  }

  /// TODO: Thay 'REPLACE_WITH_WEB_APP_ID' bằng Web App ID thực từ:
  /// Firebase Console → Project giadinh-ca079 → Project Settings → Your apps → Web app → appId
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGgE1EgumkGx2LBoiOnDDTzix8tCX4GGI',
    appId: '1:10762035761:web:f60a1c5582fd3cc2ab6b10',
    messagingSenderId: '10762035761',
    projectId: 'giadinh-ca079',
    authDomain: 'giadinh-ca079.firebaseapp.com',
    storageBucket: 'giadinh-ca079.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGgE1EgumkGx2LBoiOnDDTzix8tCX4GGI',
    appId: '1:10762035761:android:18649c685a13db39ab6b10',
    messagingSenderId: '10762035761',
    projectId: 'giadinh-ca079',
    storageBucket: 'giadinh-ca079.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDhZO1nTMg1GGV2RhlCu8JubcgxvSheX-Q',
    appId: '1:10762035761:ios:3760b98c953b58c0ab6b10',
    messagingSenderId: '10762035761',
    projectId: 'giadinh-ca079',
    storageBucket: 'giadinh-ca079.firebasestorage.app',
    iosBundleId: 'com.huluca.family',
  );
}
