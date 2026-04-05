// Placeholder — regenerate with: flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvz0z5PUnpS2eIIo2UuYdA59xEH3D8vv4',
    appId: '1:282452142394:android:697f8da8a8854c9b490803',
    messagingSenderId: '282452142394',
    projectId: 'shape-merge',
    storageBucket: 'shape-merge.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'shape-merge',
    storageBucket: 'shape-merge.appspot.com',
    iosBundleId: 'com.crestbit.shapeMerge',
  );
}