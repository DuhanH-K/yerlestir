import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Native iOS configuration comes exclusively from GoogleService-Info.plist.
/// No Android Firebase app or custom first_open event is created here.
class IosAnalytics {
  Future<bool>? _initialization;

  Future<bool> initialize() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future.value(false);
    }
    return _initialization ??= _initialize();
  }

  Future<bool> _initialize() async {
    try {
      final app = await Firebase.initializeApp();
      if (app.options.iosBundleId != 'com.yerlestir.game.yerlestir') {
        throw StateError('Firebase iOS configuration has the wrong Bundle ID.');
      }
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      if (kDebugMode) {
        debugPrint(
          '[Analytics][iOS] Firebase initialized; collection enabled.',
        );
      }
      return true;
    } catch (error) {
      // Missing native config must not prevent the game from starting.
      if (kDebugMode) {
        debugPrint('[Analytics][iOS] Initialization unavailable: $error');
      }
      return false;
    }
  }
}
