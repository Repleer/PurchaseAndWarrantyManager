import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:warranty_and_purchase_manager/app.dart';
import 'package:warranty_and_purchase_manager/core/features/analytics/data/analytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/data/auth_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/crashlytics/data/crashlytics_service.dart';
import 'package:warranty_and_purchase_manager/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final bool useCrashlytics = !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);
  final CrashlyticsService crashlyticsService;
  if (useCrashlytics) {
    if (!kIsWeb) await GoogleSignIn.instance.initialize();
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
    crashlyticsService = CrashlyticsService.firebase(crashlytics);
  } else {
    crashlyticsService = CrashlyticsService.sentry();
  }

  final FirebaseAuthRepository authRepository =
      FirebaseAuthRepository(FirebaseAuth.instance, GoogleSignIn.instance);
  final AnalyticsService analytics =
      AnalyticsService(FirebaseAnalytics.instance);

  final Widget application = MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<AnalyticsService>.value(value: analytics),
        Provider<CrashlyticsService>.value(value: crashlyticsService),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(
            authRepository,
            analytics,
          ),
        ),
      ],
      child: const WarrantyManagerApp(),
    );

  if (useCrashlytics) {
    runApp(application);
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
      },
      appRunner: () => runApp(application),
    );
  }
}
