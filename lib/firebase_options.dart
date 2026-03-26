// IMPORTANT: This file contains placeholder values.
// You MUST replace them before Firebase will work.
//
// Steps:
//   1. Go to https://console.firebase.google.com
//   2. Create or select your Firebase project
//   3. Add Android, iOS and Web apps for this portal app
//   4. Run: flutterfire configure
//      (This auto-generates correct values for all platforms)
//   OR manually paste values from:
//      Firebase Console → Project Settings → Your Apps

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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── REPLACE ALL VALUES BELOW ────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeX1XoNNCCqLlRalpjGmHEHwmkza23Nl0',
    appId: '1:27851314244:web:63e66501eb4b5c07df9811',
    messagingSenderId: '27851314244',
    projectId: 'walldot-portal-73856',
    authDomain: 'walldot-portal-73856.firebaseapp.com',
    storageBucket: 'walldot-portal-73856.firebasestorage.app',
    measurementId: 'G-J9XD9PXCE5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1EiEgMRPu5fvrx4cun0yM0MHHCf-SMYw',
    appId: '1:27851314244:android:3e380cb09a6790d1df9811',
    messagingSenderId: '27851314244',
    projectId: 'walldot-portal-73856',
    storageBucket: 'walldot-portal-73856.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB45KB_5ChiBY16YuHVqqLBLEeFTk2DbX4',
    appId: '1:27851314244:ios:e3c8bfc4ce3a5d07df9811',
    messagingSenderId: '27851314244',
    projectId: 'walldot-portal-73856',
    storageBucket: 'walldot-portal-73856.firebasestorage.app',
    iosBundleId: 'com.example.wdPortal',
  );

}