// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDxQoFP_SU43IIpIOVGNoU1DK3tYcs1yvw',
    appId: '1:246539347393:web:0e8b8038700f0541697b40',
    messagingSenderId: '246539347393',
    projectId: 'taskii-bf674',
    authDomain: 'taskii-bf674.firebaseapp.com',
    databaseURL: 'https://taskii-bf674-default-rtdb.firebaseio.com',
    storageBucket: 'taskii-bf674.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnrhTb1Wlh0LUT24BlQfXSfLtL8rG0-GA',
    appId: '1:246539347393:android:7e1af2a519a9a64d697b40',
    messagingSenderId: '246539347393',
    projectId: 'taskii-bf674',
    databaseURL: 'https://taskii-bf674-default-rtdb.firebaseio.com',
    storageBucket: 'taskii-bf674.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDpfVUKD7QQzgS4xACDAN57dsXoYdQttvY',
    appId: '1:246539347393:ios:887af18b350ab3a3697b40',
    messagingSenderId: '246539347393',
    projectId: 'taskii-bf674',
    databaseURL: 'https://taskii-bf674-default-rtdb.firebaseio.com',
    storageBucket: 'taskii-bf674.firebasestorage.app',
    iosBundleId: 'io.teamh.taskii',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDpfVUKD7QQzgS4xACDAN57dsXoYdQttvY',
    appId: '1:246539347393:ios:93f7ce2dc7b2491c697b40',
    messagingSenderId: '246539347393',
    projectId: 'taskii-bf674',
    databaseURL: 'https://taskii-bf674-default-rtdb.firebaseio.com',
    storageBucket: 'taskii-bf674.firebasestorage.app',
    iosBundleId: 'io.teamh.taskii',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDxQoFP_SU43IIpIOVGNoU1DK3tYcs1yvw',
    appId: '1:246539347393:web:7b6eb31e7bdd3ad2697b40',
    messagingSenderId: '246539347393',
    projectId: 'taskii-bf674',
    authDomain: 'taskii-bf674.firebaseapp.com',
    databaseURL: 'https://taskii-bf674-default-rtdb.firebaseio.com',
    storageBucket: 'taskii-bf674.firebasestorage.app',
  );

}