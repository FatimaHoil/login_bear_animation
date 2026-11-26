import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrgjDlKzqOPFYBKwXIeU6YGdXxqmMQyiI',
    authDomain: 'flutter-market-app-ef1ce.firebaseapp.com',
    projectId: 'flutter-market-app-ef1ce',
    storageBucket: 'flutter-market-app-ef1ce.firebasestorage.app',
    messagingSenderId: '487776843430',
    appId: '1:487776843430:web:72a913bb7266cd6c5ca667',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATObiaWljuiYOuJHdJnxGXUmDMFJc5bnA',
    projectId: 'flutter-market-app-ef1ce',
    storageBucket: 'flutter-market-app-ef1ce.firebasestorage.app',
    messagingSenderId: '487776843430',
    appId: '1:487776843430:android:7e7cf0f954b6fc775ca667',
  );
}
