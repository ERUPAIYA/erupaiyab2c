import 'package:firebase_core/firebase_core.dart';

/// Explicit FirebaseOptions for Android packages.
///
/// Use this when you want to avoid relying on platform auto-configuration.
class ExplicitFirebaseOptions {
  const ExplicitFirebaseOptions._();

  /// Android package `com.innoplix.erupaiya`.
  static const FirebaseOptions androidErupaiya = FirebaseOptions(
    apiKey: 'AIzaSyCdEhBeVZUgoAiqKcDhgD0slpa6xbo9B7w',
    appId: '1:715562519142:android:6f7b93fa749fe881057ba7',
    messagingSenderId: '715562519142',
    projectId: 'erupaiya-f9411',
    storageBucket: 'erupaiya-f9411.firebasestorage.app',
  );

  /// Android package `com.innoplix.erupiya` (legacy/alt flavor).
  static const FirebaseOptions androidErupiya = FirebaseOptions(
    apiKey: 'AIzaSyCdEhBeVZUgoAiqKcDhgD0slpa6xbo9B7w',
    appId: '1:715562519142:android:e2a8f61fb7628bc6057ba7',
    messagingSenderId: '715562519142',
    projectId: 'erupaiya-f9411',
    storageBucket: 'erupaiya-f9411.firebasestorage.app',
  );
}
