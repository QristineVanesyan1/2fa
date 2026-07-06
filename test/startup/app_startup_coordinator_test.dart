import 'package:authenticator/services/onboarding_service.dart';
import 'package:authenticator/services/purchase_service.dart';
import 'package:authenticator/startup/app_startup_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStartupCoordinator.resolveInitialDestination', () {
    test('new user (onboarding incomplete) goes to onboarding', () async {
      final coordinator = AppStartupCoordinator(
        onboardingService: InMemoryOnboardingService(complete: false),
        purchaseService: FakePurchaseService(result: true),
      );

      expect(
        await coordinator.resolveInitialDestination(),
        StartupDestination.onboarding,
      );
    });

    test('returning user with active subscription goes to home', () async {
      final coordinator = AppStartupCoordinator(
        onboardingService: InMemoryOnboardingService(complete: true),
        purchaseService: FakePurchaseService(result: true),
      );

      expect(
        await coordinator.resolveInitialDestination(),
        StartupDestination.home,
      );
    });

    test('returning user without subscription goes to paywall', () async {
      final coordinator = AppStartupCoordinator(
        onboardingService: InMemoryOnboardingService(complete: true),
        purchaseService: FakePurchaseService(result: false),
      );

      expect(
        await coordinator.resolveInitialDestination(),
        StartupDestination.paywall,
      );
    });

    test('propagates entitlement-check errors', () async {
      final coordinator = AppStartupCoordinator(
        onboardingService: InMemoryOnboardingService(complete: true),
        purchaseService: FakePurchaseService(error: Exception('network')),
      );

      expect(
        () => coordinator.resolveInitialDestination(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AppStartupCoordinator.completeOnboardingAndResolve', () {
    test('persists onboarding completion and resolves entitlement', () async {
      final onboarding = InMemoryOnboardingService(complete: false);
      final coordinator = AppStartupCoordinator(
        onboardingService: onboarding,
        purchaseService: FakePurchaseService(result: false),
      );

      final destination = await coordinator.completeOnboardingAndResolve();

      expect(destination, StartupDestination.paywall);
      expect(await onboarding.isOnboardingComplete(), isTrue);
    });

    test('returning users never see onboarding again', () async {
      final onboarding = InMemoryOnboardingService(complete: false);
      final coordinator = AppStartupCoordinator(
        onboardingService: onboarding,
        purchaseService: FakePurchaseService(result: true),
      );

      // First launch -> onboarding.
      expect(
        await coordinator.resolveInitialDestination(),
        StartupDestination.onboarding,
      );

      // Finish onboarding.
      await coordinator.completeOnboardingAndResolve();

      // Next launch -> no onboarding.
      expect(
        await coordinator.resolveInitialDestination(),
        isNot(StartupDestination.onboarding),
      );
    });
  });
}
