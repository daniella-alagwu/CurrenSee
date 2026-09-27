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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7OKSspSmExlbtm6kDtm5qT6lQAlCK1KQ',
    appId: '1:513087315519:web:1bfce191bc1911f276a28a',
    messagingSenderId: '513087315519',
    projectId: 'currensee-6633a',
    authDomain: 'currensee-6633a.firebaseapp.com',
    storageBucket: 'currensee-6633a.firebasestorage.app',
    measurementId: 'G-D75GJ0RGY9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAZzFh68_3Kv00R1mry7aqfTtfqO3isCc',
    appId: '1:513087315519:android:bb5c264020ff19db76a28a',
    messagingSenderId: '513087315519',
    projectId: 'currensee-6633a',
    storageBucket: 'currensee-6633a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuS36VzAnKbqnAkgNOkkkIyjDvBi1pXaU',
    appId: '1:513087315519:ios:a4a09ad72411c56176a28a',
    messagingSenderId: '513087315519',
    projectId: 'currensee-6633a',
    storageBucket: 'currensee-6633a.firebasestorage.app',
    iosBundleId: 'com.example.currensee',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDuS36VzAnKbqnAkgNOkkkIyjDvBi1pXaU',
    appId: '1:513087315519:ios:a4a09ad72411c56176a28a',
    messagingSenderId: '513087315519',
    projectId: 'currensee-6633a',
    storageBucket: 'currensee-6633a.firebasestorage.app',
    iosBundleId: 'com.example.currensee',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB7OKSspSmExlbtm6kDtm5qT6lQAlCK1KQ',
    appId: '1:513087315519:web:02899856a63e6b7c76a28a',
    messagingSenderId: '513087315519',
    projectId: 'currensee-6633a',
    authDomain: 'currensee-6633a.firebaseapp.com',
    storageBucket: 'currensee-6633a.firebasestorage.app',
    measurementId: 'G-PBL29KJLFB',
  );
}
