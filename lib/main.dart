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
import 'package:warranty_and_purchase_manager/core/features/purchases/data/purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/application/purchases_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/purchases/data/local_file_purchase_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/application/claims_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/local_file_claim_repository.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/warranty_verification_service.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/shared_preferences_profile_cache.dart';
import 'package:warranty_and_purchase_manager/core/data/app_preferences.dart';
import 'package:warranty_and_purchase_manager/core/data/json_file_store.dart';
import 'package:warranty_and_purchase_manager/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  final bool useCrashlytics =
      !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);
  final CrashlyticsService crashlyticsService;
  if (useCrashlytics) {
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

  final FirebaseAuthRepository authRepository = FirebaseAuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn.instance,
  );
  final AnalyticsService analytics = AnalyticsService(
    FirebaseAnalytics.instance,
  );
  final JsonFileStore fileStore = JsonFileStore();
  if (kDebugMode) {
    final String basePath = (await fileStore.baseDirectory()).path;
    debugPrint('Каталог локальних даних: $basePath/users');
  }
  final PurchaseRepository purchaseRepository = LocalFilePurchaseRepository(
    fileStore,
  );
  final ClaimRepository claimRepository = LocalFileClaimRepository(fileStore);
  final WarrantyVerificationService warrantyVerificationService =
      MockWarrantyVerificationService();
  final AppPreferences prefs = await AppPreferences.create();
  final ProfileCache profileCache = SharedPreferencesProfileCache(prefs);

  final Widget application = MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: authRepository),
      Provider<AppPreferences>.value(value: prefs),
      Provider<AnalyticsService>.value(value: analytics),
      Provider<PurchaseRepository>.value(value: purchaseRepository),
      ChangeNotifierProvider<PurchasesController>(
        create: (ctx) => PurchasesController(
          ctx.read<PurchaseRepository>(),
          preferences: ctx.read<AppPreferences>(),
        ),
      ),
      Provider<ClaimRepository>.value(value: claimRepository),
      Provider<WarrantyVerificationService>.value(
        value: warrantyVerificationService,
      ),
      Provider<ProfileCache>.value(value: profileCache),
      ChangeNotifierProvider<ProfileController>(
        create: (ctx) => ProfileController(
          ctx.read<AuthRepository>(),
          ctx.read<ProfileCache>(),
          analytics: ctx.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider<ClaimsController>(
        create: (ctx) => ClaimsController(
          ctx.read<ClaimRepository>(),
          ctx.read<WarrantyVerificationService>(),
          preferences: ctx.read<AppPreferences>(),
        ),
      ),
      Provider<CrashlyticsService>.value(value: crashlyticsService),
      ChangeNotifierProvider<AuthController>(
        create: (_) =>
            AuthController(authRepository, analytics, preferences: prefs),
      ),
    ],
    child: const WarrantyManagerApp(),
  );

  if (useCrashlytics) {
    runApp(application);
  } else {
    await SentryFlutter.init((options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
    }, appRunner: () => runApp(application));
  }
}
