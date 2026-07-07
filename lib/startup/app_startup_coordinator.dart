import 'package:authenticator/services/app_lock_service.dart';
import 'package:authenticator/services/onboarding_service.dart';
import 'package:authenticator/services/purchase_service.dart';

/// Where the app should land after the startup checks have finished.
enum StartupDestination {
  /// User has not completed onboarding yet.
  onboarding,

  /// User is entitled — go straight to the main app.
  home,

  /// User is not entitled — show the paywall.
  paywall,
}

/// Centralised launch flow.
///
/// Owns the ordered list of startup checks (onboarding, entitlement, …) and
/// resolves them into a single [StartupDestination]. New checks (remote config,
/// force-update, authentication, …) can be added here without touching the UI.
///
/// The class is intentionally UI-free so it can be unit-tested in isolation.
class AppStartupCoordinator {
  const AppStartupCoordinator({
    required this.onboardingService,
    required this.purchaseService,
    required this.appLockService,
  });

  final OnboardingService onboardingService;
  final PurchaseService purchaseService;
  final AppLockService appLockService;

  /// Whether the app should present a lock screen (passcode / Face ID) before
  /// revealing any content, based on the user's security settings.
  Future<bool> isLockEnabled() => appLockService.isLockEnabled();

  /// Resolves the destination for a fresh app launch.
  ///
  /// 1. If onboarding is not complete -> [StartupDestination.onboarding].
  /// 2. Otherwise the subscription/entitlement check decides between
  ///    [StartupDestination.home] and [StartupDestination.paywall].
  ///
  /// May throw if a check fails (e.g. the entitlement lookup errors). Callers
  /// are expected to surface a retry state.
  Future<StartupDestination> resolveInitialDestination() async {
    final onboardingComplete = await onboardingService.isOnboardingComplete();

    if (!onboardingComplete) {
      return StartupDestination.onboarding;
    }
    return _resolveEntitlementDestination();
  }

  /// Called once the user has just finished onboarding.
  ///
  /// Persists completion locally so onboarding is never shown again, then
  /// continues with the entitlement check.
  Future<StartupDestination> completeOnboardingAndResolve() async {
    await onboardingService.setOnboardingComplete();

    return _resolveEntitlementDestination();
  }

  Future<StartupDestination> _resolveEntitlementDestination() async {
    final hasSubscription = await purchaseService.hasActiveSubscription();

    return hasSubscription
        ? StartupDestination.home
        : StartupDestination.paywall;
  }
}
