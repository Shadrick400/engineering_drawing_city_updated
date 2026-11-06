// File generated for Engineering Drawing City Firebase Configuration
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
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyEngineeringDrawingCityWebKey2026',
    appId: '1:108392847581:web:5b32389182049182390192',
    messagingSenderId: '108392847581',
    projectId: 'engineering-drawing-city',
    authDomain: 'engineering-drawing-city.firebaseapp.com',
    storageBucket: 'engineering-drawing-city.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyEngineeringDrawingCityAndroidKey2026',
    appId: '1:108392847581:android:3c84729182049182390192',
    messagingSenderId: '108392847581',
    projectId: 'engineering-drawing-city',
    storageBucket: 'engineering-drawing-city.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyEngineeringDrawingCityIOSKey2026',
    appId: '1:108392847581:ios:4d93829182049182390192',
    messagingSenderId: '108392847581',
    projectId: 'engineering-drawing-city',
    storageBucket: 'engineering-drawing-city.appspot.com',
    iosBundleId: 'com.drawingcity.engineeringDrawingCity',
  );
}
