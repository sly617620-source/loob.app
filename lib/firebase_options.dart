import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Reads configuration from compile-time environment variables (--dart-define).
/// Example build command:
/// ```bash
/// flutter build apk --release \
///   --dart-define=FIREBASE_API_KEY_ANDROID=your_key \
///   --dart-define=FIREBASE_PROJECT_ID=your_project_id
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Helper to read compile-time variables with defaults from google-services.json
  static const String _apiKeyAndroid = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
    defaultValue: 'AIzaSyA6hbtxBIuHm8T-bdAZn-jr5oPnM-VuzwU',
  );
  static const String _apiKeyIos = String.fromEnvironment('FIREBASE_API_KEY_IOS');
  static const String _apiKeyWeb = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const String _appIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
    defaultValue: '1:202069212336:android:dcd0a031160a60f3584f75',
  );
  static const String _appIdIos = String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const String _appIdWeb = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '202069212336',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'loob-app',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'loob-app.firebaseapp.com',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'loob-app.firebasestorage.app',
  );
  static const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.wolf.loob',
  );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKeyWeb,
        appId: _appIdWeb,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
        measurementId: _measurementId,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKeyAndroid,
        appId: _appIdAndroid,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKeyIos,
        appId: _appIdIos,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _apiKeyIos,
        appId: _appIdIos,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );
}
