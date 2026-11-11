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
    apiKey: 'AIzaSyDcXc3b39cK3z7XBazwojDyEm5JS7eupWI',
    authDomain: 'login-bear-animation.firebaseapp.com',
    projectId: 'login-bear-animation',
    storageBucket: 'login-bear-animation.firebasestorage.app',
    messagingSenderId: '1002667843221',
    appId: '1:1002667843221:web:2759eaefc5f39fae78c59c',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcXc3b39cK3z7XBazwojDyEm5JS7eupWI',
    projectId: 'login-bear-animation',
    storageBucket: 'login-bear-animation.firebasestorage.app',
    messagingSenderId: '1002667843221',
    appId: '1:1002667843221:web:2759eaefc5f39fae78c59c',
  );
}
