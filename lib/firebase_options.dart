import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// File opsi konfigurasi Firebase standar untuk semua platform (Android, Web, Windows, iOS)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return web;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHF-Es4yM5YcMD60e7M6Jp9Zv3RV3lD_I',
    appId: '1:154794293374:android:48ff499e6745dae8e9402f',
    messagingSenderId: '154794293374',
    projectId: 'possmart-app',
    storageBucket: 'possmart-app.firebasestorage.app',
    databaseURL: 'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHF-Es4yM5YcMD60e7M6Jp9Zv3RV3lD_I',
    appId: '1:154794293374:web:48ff499e6745dae8e9402f',
    messagingSenderId: '154794293374',
    projectId: 'possmart-app',
    storageBucket: 'possmart-app.firebasestorage.app',
    databaseURL: 'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCHF-Es4yM5YcMD60e7M6Jp9Zv3RV3lD_I',
    appId: '1:154794293374:web:48ff499e6745dae8e9402f',
    messagingSenderId: '154794293374',
    projectId: 'possmart-app',
    storageBucket: 'possmart-app.firebasestorage.app',
    databaseURL: 'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHF-Es4yM5YcMD60e7M6Jp9Zv3RV3lD_I',
    appId: '1:154794293374:ios:48ff499e6745dae8e9402f',
    messagingSenderId: '154794293374',
    projectId: 'possmart-app',
    storageBucket: 'possmart-app.firebasestorage.app',
    databaseURL: 'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCHF-Es4yM5YcMD60e7M6Jp9Zv3RV3lD_I',
    appId: '1:154794293374:ios:48ff499e6745dae8e9402f',
    messagingSenderId: '154794293374',
    projectId: 'possmart-app',
    storageBucket: 'possmart-app.firebasestorage.app',
    databaseURL: 'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
