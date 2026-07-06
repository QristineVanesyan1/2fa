import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/splash_screen.dart';
import 'package:authenticator/services/onboarding_service.dart';
import 'package:authenticator/services/purchase_service.dart';
import 'package:authenticator/startup/app_startup_coordinator.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Compose the startup dependencies here so they are easy to swap (e.g. a real
  // store-backed PurchaseService) and to inject in tests.
  final coordinator = AppStartupCoordinator(
    onboardingService: SharedPrefsOnboardingService(),
    purchaseService: StubPurchaseService(),
  );

  runApp(MyApp(coordinator: coordinator));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.coordinator});

  final AppStartupCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authenticator',
      theme: ThemeData(
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
      // home: SplashScreen(),
    );
  }
}
