import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Boots Firebase before `runApp`: core, Crashlytics error hooks and the
/// FCM background handler. Remote Config and notification permissions are
/// started separately so they never block the first frame.
class FirebaseSetup {
  FirebaseSetup._();

  static Future<void> init() async {
    // Config comes from google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();

    final crashlytics = FirebaseCrashlytics.instance;
    // Debug crashes stay in the console instead of polluting the dashboard.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Ties crash reports to the logged-in user (cleared on logout).
  static Future<void> setUser(String? userId) =>
      FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
}
