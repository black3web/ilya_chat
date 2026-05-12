// File: lib/firebase_options.dart
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMwzcHwfj_tBQLS6c9bLoY1-hnegUjsqI',
    authDomain: 'ilya-chat.firebaseapp.com',
    projectId: 'ilya-chat',
    storageBucket: 'ilya-chat.firebasestorage.app',
    messagingSenderId: '324624675054',
    appId: '1:324624675054:web:50b4ffbc0de8a3f69383ff',
    measurementId: 'G-4X2H4XXJHJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbyqLth3SGGjS7XhC9YHsAKwf3z5JOi2o',
    appId: '1:324624675054:android:da66c30beb42461b9383ff',
    messagingSenderId: '324624675054',
    projectId: 'ilya-chat',
    storageBucket: 'ilya-chat.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRJuGvYLezbuSJ75bh_Mj6vpcqHRDYZRU',
    appId: '1:324624675054:ios:92870a6982973d3c9383ff',
    messagingSenderId: '324624675054',
    projectId: 'ilya-chat',
    storageBucket: 'ilya-chat.firebasestorage.app',
    iosClientId: 'com.ilya.chat',
    iosBundleId: 'com.ilya.chat',
  );
}
