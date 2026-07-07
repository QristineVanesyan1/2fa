// Widget tests for the app startup / splash flow.

import 'package:authenticator/screens/splash_screen.dart';
import 'package:authenticator/services/app_lock_service.dart';
import 'package:authenticator/services/onboarding_service.dart';
import 'package:authenticator/services/purchase_service.dart';

import 'package:authenticator/startup/app_startup_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(AppStartupCoordinator coordinator) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(coordinator: coordinator),
  );
}

void main() {
  testWidgets('shows a preloader immediately on launch', (tester) async {
    final coordinator = AppStartupCoordinator(
      onboardingService: InMemoryOnboardingService(complete: true),
      purchaseService: FakePurchaseService(result: false),
      appLockService: InMemoryAppLockService(),
    );

    await tester.pumpWidget(_wrap(coordinator));

    // First frame: preloader is visible before checks resolve.

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('returning user without subscription lands on the paywall', (
    tester,
  ) async {
    final coordinator = AppStartupCoordinator(
      onboardingService: InMemoryOnboardingService(complete: true),
      purchaseService: FakePurchaseService(result: false),
      appLockService: InMemoryAppLockService(),
    );

    await tester.pumpWidget(_wrap(coordinator));
    await tester.pumpAndSettle();

    // Paywall screen content is shown, splash preloader is gone.

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('failed subscription check shows a retry state', (tester) async {
    final purchases = FakePurchaseService(error: Exception('network'));
    final coordinator = AppStartupCoordinator(
      onboardingService: InMemoryOnboardingService(complete: true),
      purchaseService: purchases,
      appLockService: InMemoryAppLockService(),
    );

    await tester.pumpWidget(_wrap(coordinator));
    await tester.pumpAndSettle();

    // Error state instead of a blank screen.
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Fix the underlying error and retry -> navigate to the paywall.
    purchases.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });
}
