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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUSbtZyDl-Vj3KmbP_Ek14uI80gokXEKY',
    authDomain: 'ambw-swalayan.firebaseapp.com',
    projectId: 'ambw-swalayan',
    storageBucket: 'ambw-swalayan.firebasestorage.app',
    messagingSenderId: '855609739135',
    appId: '1:855609739135:web:a591b11f6590d72e297c4a',
    measurementId: 'G-Z89B6BRM2F',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUSbtZyDl-Vj3KmbP_Ek14uI80gokXEKY',
    projectId: 'ambw-swalayan',
    storageBucket: 'ambw-swalayan.firebasestorage.app',
    messagingSenderId: '855609739135',
    appId: '1:855609739135:web:a591b11f6590d72e297c4a',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUSbtZyDl-Vj3KmbP_Ek14uI80gokXEKY',
    projectId: 'ambw-swalayan',
    storageBucket: 'ambw-swalayan.firebasestorage.app',
    messagingSenderId: '855609739135',
    appId: '1:855609739135:web:a591b11f6590d72e297c4a',
    iosBundleId: 'com.example.ambwswalayan',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDUSbtZyDl-Vj3KmbP_Ek14uI80gokXEKY',
    projectId: 'ambw-swalayan',
    storageBucket: 'ambw-swalayan.firebasestorage.app',
    messagingSenderId: '855609739135',
    appId: '1:855609739135:web:a591b11f6590d72e297c4a',
    iosBundleId: 'com.example.ambwswalayan',
  );
}
