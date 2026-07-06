/// Abstraction over the app's purchase / subscription backend.
///
/// A real implementation would talk to StoreKit / Google Play Billing or a
/// wrapper such as RevenueCat. The startup flow only cares about entitlement,
/// so the surface is intentionally tiny and easy to fake in tests.
abstract class PurchaseService {
  /// Returns `true` when the user currently has an active entitlement.
  ///
  /// May throw if the entitlement check fails (e.g. network error). The
  /// startup flow catches this and shows a retry state.
  Future<bool> hasActiveSubscription();
}

/// Default stub implementation.
///
/// Replace with a real store-backed implementation. It intentionally simulates
/// latency so the splash/preloader behaviour can be observed, and defaults to
/// "no active subscription" so new users are routed to the paywall.
class StubPurchaseService implements PurchaseService {
  StubPurchaseService({
    this.hasSubscription = false,
    this.latency = const Duration(milliseconds: 400),
  });

  final bool hasSubscription;
  final Duration latency;

  @override
  Future<bool> hasActiveSubscription() async {
    await Future<void>.delayed(latency);
    return hasSubscription;
  }
}

/// Deterministic [PurchaseService] for tests.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.result = false, this.error});

  bool result;
  Object? error;

  @override
  Future<bool> hasActiveSubscription() async {
    if (error != null) throw error!;
    return result;
  }
}
