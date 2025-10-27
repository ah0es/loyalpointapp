import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnzYqzyQQgDlp2iHSuFQXhGKsU98VMZBs',
    appId: '1:377453510143:web:4092021543eb2ee77efbca',
    messagingSenderId: '377453510143',
    projectId: 'loyalty-card-app-b8957',
    storageBucket: 'loyalty-card-app-b8957.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnzYqzyQQgDlp2iHSuFQXhGKsU98VMZBs',
    appId: '1:377453510143:web:4092021543eb2ee77efbca', // Use web app ID for now
    messagingSenderId: '377453510143',
    projectId: 'loyalty-card-app-b8957',
    storageBucket: 'loyalty-card-app-b8957.firebasestorage.app',
    iosBundleId: 'com.example.loyalpointapp',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnzYqzyQQgDlp2iHSuFQXhGKsU98VMZBs',
    appId: '1:377453510143:web:4092021543eb2ee77efbca', // Use web app ID for now
    messagingSenderId: '377453510143',
    projectId: 'loyalty-card-app-b8957',
    storageBucket: 'loyalty-card-app-b8957.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCnzYqzyQQgDlp2iHSuFQXhGKsU98VMZBs',
    appId: '1:377453510143:web:4092021543eb2ee77efbca', // Use web app ID for now
    messagingSenderId: '377453510143',
    projectId: 'loyalty-card-app-b8957',
    storageBucket: 'loyalty-card-app-b8957.firebasestorage.app',
    iosBundleId: 'com.example.loyalpointapp',
  );
}
