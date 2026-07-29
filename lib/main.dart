import 'package:authenticator/const/colors.dart';

import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/splash_screen.dart';
import 'package:authenticator/services/adapty_service.dart';
import 'package:authenticator/services/app_lock_service.dart';
import 'package:authenticator/services/onboarding_service.dart';
import 'package:authenticator/services/purchase_service.dart';

import 'package:authenticator/startup/app_startup_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single entry point for Adapty activation.
///
/// [AdaptyService.activate] is itself idempotent (it checks both a Dart-side
/// flag and the native `Adapty().isActivated()` state), so this must be the
/// only place in the app that kicks off activation — never call it from a
/// widget's `initState`, since a rebuild would attempt a second activation.
Future<void> activateAdapty() => AdaptyService.instance.activate();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Compose the startup dependencies here so they are easy to swap (e.g. a real
  // store-backed PurchaseService) and to inject in tests.
  // Activate the Adapty SDK as early as possible so entitlement checks and the
  // paywall are ready by the time the splash flow needs them. Activation never
  // throws, so a failure here won't block startup.
  await activateAdapty();

  // Compose the startup dependencies here so they are easy to swap and to
  // inject in tests. Entitlement is now backed by Adapty.
  final coordinator = AppStartupCoordinator(
    onboardingService: SharedPrefsOnboardingService(),
    purchaseService: AdaptyPurchaseService(),
    appLockService: SharedPrefsAppLockService(),
  );

  runApp(MyApp(coordinator: coordinator));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.coordinator});

  final AppStartupCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      title: '2FA App Authenticator',
      theme: ThemeData(
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.orange500,

          elevation: 4,
        ),
        fontFamily: AppTextStyles.fontFamily,
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.display,
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          headlineSmall: AppTextStyles.h3,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.button,
          labelMedium: AppTextStyles.captionMedium,
          labelSmall: AppTextStyles.caption,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(coordinator: coordinator),
    );
  }
}
