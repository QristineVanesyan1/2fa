import 'dart:async';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around the Adapty SDK.
///
/// Centralises all Adapty configuration (keys, placement / access-level
/// identifiers) and the handful of calls the app actually needs: activation,
/// entitlement checks, fetching the paywall + its products, purchasing and
/// restoring. Keeping this in one place means the rest of the app never has to
/// import `adapty_flutter` directly and the SDK can be swapped/mocked easily.
class AdaptyService {
  AdaptyService._();

  /// Singleton instance used across the app.
  static final AdaptyService instance = AdaptyService._();

  /// Public SDK key from your Adapty dashboard (App Settings -> General).
  static const String _apiKey = 'public_live_R054KOek.9S1LJIcEkTYF0DbpSK66';

  /// The placement configured in the Adapty dashboard that maps to the app's
  /// paywall.
  ///
  /// Resolves to the `premium` paywall, which serves three auto-renewable
  /// subscriptions (weekly / monthly / annual). This must be the **Placement
  /// ID** from Monetization -> Placements — a paywall is only reachable from
  /// the SDK once it's attached to a placement.
  static const String placementId = 'main';

  /// The access level ("entitlement") that grants premium features.
  /// This is the id you configured under Access Levels in Adapty (default is
  /// usually `premium`).
  static const String premiumAccessLevelId = 'premium';

  /// Adapty error code returned when `activate()` is called on an SDK that is
  /// already activated (`AdaptyError.activateOnceError`).
  static const int _alreadyActivatedCode = 3005;

  /// Adapty error code returned when StoreKit / Google Play knows none of the
  /// product IDs attached to the paywall
  /// (`StoreKitManagerError.noProductIDsFound`).
  ///
  /// This is always a *configuration* problem, never a code one — see
  /// [_logNoProductsDiagnostics] for the checklist.
  static const int noProductsFoundCode = 1000;

  /// Budget for a single Adapty network request.
  ///
  /// The SDK's own default is ~30s, which is long enough that a flaky network
  /// makes the splash screen look permanently frozen (the startup entitlement
  /// check awaits this). Failing fast lets the UI show a retry / fall back to
  /// placeholder plans instead of hanging.
  static const Duration _networkTimeout = Duration(seconds: 8);

  /// Activation runs *before* `runApp`, so a stall here delays the very first
  /// frame. It's mostly local work, hence a shorter leash than a data request.
  static const Duration _activationTimeout = Duration(seconds: 5);

  bool _activated = false;

  /// Whether the SDK has been successfully activated.
  bool get isActivated => _activated;

  /// `true` when the Public SDK key hasn't been filled in yet. Used to skip
  /// activation so a placeholder key doesn't crash the app (the native SDK
  /// throws an uncatchable assertion on an obviously-invalid key).
  bool get _hasValidKey => _apiKey.isNotEmpty && _apiKey != 'PUBLIC_SDK_KEY';

  /// Activates the Adapty SDK. Safe to call multiple times — subsequent calls
  /// are no-ops. Never throws: activation failures are logged and swallowed so
  /// they can't block app startup.
  ///
  /// Guards against the `activateOnceError` (3005) crash in two layers:
  ///  1. [_activated] short-circuits repeat calls within one Dart isolate.
  ///  2. [Adapty.isActivated] asks the *native* SDK whether it is already
  ///     running. On a Flutter hot restart the Dart isolate is recreated
  ///     (resetting [_activated]) while the native SDK survives from the
  ///     previous run, so we re-attach the plugin's method-call handler via
  ///     [Adapty.setupAfterHotRestart] instead of activating a second time.
  Future<void> activate() async {
    if (_activated) return;
    if (!_hasValidKey) {
      debugPrint(
        'Adapty: skipping activation — set your Public SDK key in '
        'AdaptyService._apiKey to enable subscriptions.',
      );
      return;
    }
    try {
      await Adapty().setLogLevel(
        kReleaseMode ? AdaptyLogLevel.error : AdaptyLogLevel.verbose,
      );

      // Ask the native side first: after a hot restart it is still activated.
      if (await Adapty().isActivated().timeout(_activationTimeout)) {
        debugPrint(
          'Adapty: native SDK already activated (hot restart) — re-attaching '
          'the plugin instead of calling activate() again.',
        );
        _reattachAfterHotRestart();
        _activated = true;
        return;
      }

      await Adapty()
          .activate(configuration: AdaptyConfiguration(apiKey: _apiKey))
          .timeout(_activationTimeout);
      _activated = true;
    } on TimeoutException {
      // Don't block launch on a slow network — the paywall will fall back to
      // its placeholder plans and the next launch can activate again.
      debugPrint(
        'Adapty activation timed out after $_activationTimeout — continuing '
        'without subscriptions for this session.',
      );
    } on AdaptyError catch (e) {
      // Belt-and-braces: if we still raced into a second activation, the SDK
      // is alive and usable, so treat 3005 as success rather than an error.
      if (e.code == _alreadyActivatedCode) {
        debugPrint(
          'Adapty already activated (code 3005) — reusing existing SDK '
          'instance.',
        );
        _reattachAfterHotRestart();
        _activated = true;
        return;
      }
      debugPrint('Adapty activation error (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('Adapty activation error: $e');
    }
  }

  /// Re-binds the plugin's method-call handler to an already-running native
  /// SDK. Only meaningful (and only supported) in debug builds, where a hot
  /// restart can recreate the Dart isolate on top of a live native SDK.
  void _reattachAfterHotRestart() {
    if (!kDebugMode) return;
    Adapty().setupAfterHotRestart();
  }

  /// Returns `true` when the current user has an active premium access level.
  ///
  /// When the SDK isn't activated (e.g. no API key yet) this returns `false`
  /// so users are routed to the paywall rather than blocking startup. May
  /// throw [AdaptyError] (or [TimeoutException] after [_networkTimeout]) on
  /// genuine network / SDK failures so callers can surface a retry state.
  ///
  /// Adapty serves a locally cached profile when offline, so the timeout only
  /// bites when the network is reachable-but-stalled — exactly the case that
  /// would otherwise leave the splash screen spinning for ~30s.
  Future<bool> hasActiveSubscription() async {
    if (!_activated) return false;
    final profile = await Adapty().getProfile().timeout(_networkTimeout);
    return _isPremium(profile);
  }

  /// Fetches the paywall for [placementId] plus its products, ready to be
  /// rendered by a custom paywall UI. Returns an empty product list when the
  /// SDK isn't activated so the UI can fall back to placeholder plans.
  ///
  /// Only auto-renewable **subscription** products are returned — any
  /// non-subscription (consumable / non-consumable) in-app purchases attached
  /// to the paywall are filtered out, since this app sells subscriptions only.
  Future<AdaptyPaywallData> loadPaywall() async {
    // `AdaptyPaywall` has no public constructor — instances only ever come from
    // the SDK — so `null` is the sentinel for "no paywall available".
    if (!_activated) {
      return const AdaptyPaywallData(paywall: null, products: []);
    }
    // `loadTimeout` is handled natively by the SDK; the Dart-side `.timeout()`
    // on the product fetch covers the StoreKit / Billing round-trip too.
    final paywall = await Adapty().getPaywall(
      placementId: placementId,
      loadTimeout: _networkTimeout,
    );
    final List<AdaptyPaywallProduct> allProducts;
    try {
      allProducts = await Adapty()
          .getPaywallProducts(paywall: paywall)
          .timeout(_networkTimeout);
    } on AdaptyError catch (e) {
      // The paywall itself loaded (so Adapty config is reachable) but the store
      // recognised none of its product IDs. Nothing the app can do at runtime —
      // report it as an unavailable-store state and print the IDs so the
      // mismatch with App Store Connect is obvious in the logs.
      if (e.code == noProductsFoundCode) {
        _logNoProductsDiagnostics(paywall);
        return AdaptyPaywallData(
          paywall: paywall,
          products: const [],
          storeUnavailable: true,
        );
      }
      rethrow;
    }
    // Keep only auto-renewable subscriptions. A non-null `subscription` means
    // the product is an auto-renewable subscription; one-time in-app purchases
    // have a null `subscription`.
    final products = allProducts
        .where((p) => p.subscription != null)
        .toList(growable: false);
    if (products.isEmpty) {
      debugPrint(
        'Adapty: paywall "${paywall.name}" returned ${allProducts.length} '
        'product(s) but none are auto-renewable subscriptions — check that the '
        'products attached to placement "$placementId" are subscriptions.',
      );
    }
    // Fire-and-forget analytics event so Adapty can track paywall views.
    unawaited(_logShow(paywall));
    return AdaptyPaywallData(
      paywall: paywall,
      products: products,
      storeUnavailable: products.isEmpty,
    );
  }

  /// Prints the exact product IDs the store rejected, plus the checklist of
  /// configuration causes, so error 1000 can be resolved without guessing.
  void _logNoProductsDiagnostics(AdaptyPaywall paywall) {
    final ids = paywall.productIdentifiers;
    debugPrint(
      'Adapty error 1000 (noProductIDsFound): the store returned none of the '
      'product IDs attached to placement "$placementId" '
      '(paywall "${paywall.name}").\n'
      'Requested product IDs: ${ids.isEmpty ? '<none — the paywall has no products attached>' : ids.join(', ')}\n'
      'Checklist:\n'
      '  1. Each ID above must exist verbatim in App Store Connect -> '
      'Subscriptions (or Google Play -> Products).\n'
      '  2. The app bundle ID must match the App Store Connect app that owns '
      'those products (this build: com.dsmarket.authenticator2fa).\n'
      '  3. Products need complete metadata (price, localisation, review '
      'screenshot) — "Missing Metadata" products are never returned.\n'
      '  4. The Paid Applications Agreement must be active in App Store '
      'Connect.\n'
      '  5. iOS Simulator returns nothing without a StoreKit configuration '
      'file — test on a real device with a Sandbox Apple ID.\n'
      '  6. Newly created products can take up to a few hours to propagate.',
    );
  }

  /// Purchases [product] and returns `true` when the user ends up with an
  /// active premium access level (either a fresh purchase or an already-owned
  /// one). Returns `false` if the user cancelled or the SDK isn't activated.
  ///
  /// Guards against non-subscription products: this app only sells
  /// auto-renewable subscriptions, so a product without a `subscription` is
  /// rejected rather than charged.
  Future<bool> purchase(AdaptyPaywallProduct product) async {
    if (!_activated) return false;
    if (product.subscription == null) {
      debugPrint(
        'Adapty: refusing to purchase non-subscription product '
        '"${product.vendorProductId}" — subscriptions only.',
      );
      return false;
    }
    final result = await Adapty().makePurchase(product: product);
    switch (result) {
      case AdaptyPurchaseResultSuccess(profile: final profile):
        return _isPremium(profile);
      case AdaptyPurchaseResultPending():
        return false;
      case AdaptyPurchaseResultUserCancelled():
        return false;
    }
  }

  /// Restores previous purchases and returns whether premium is now active.
  Future<bool> restore() async {
    if (!_activated) return false;
    final profile = await Adapty().restorePurchases();
    return _isPremium(profile);
  }

  bool _isPremium(AdaptyProfile profile) =>
      profile.accessLevels[premiumAccessLevelId]?.isActive ?? false;

  Future<void> _logShow(AdaptyPaywall paywall) async {
    try {
      await Adapty().logShowPaywall(paywall: paywall);
    } catch (_) {
      // Analytics failures must never affect the UX.
    }
  }
}

/// Bundle of a paywall and its resolved products for the custom paywall UI.
///
/// [paywall] is `null` when the SDK isn't activated yet (placeholder key), in
/// which case [products] is empty and the UI shows placeholder plans.
class AdaptyPaywallData {
  const AdaptyPaywallData({
    required this.paywall,
    required this.products,
    this.storeUnavailable = false,
  });

  final AdaptyPaywall? paywall;
  final List<AdaptyPaywallProduct> products;

  /// `true` when the paywall was reachable but the store returned no usable
  /// subscription products (Adapty error 1000 / products misconfigured).
  ///
  /// Lets the UI tell "purchases are unavailable" apart from "still loading",
  /// instead of showing placeholder prices that can never be bought.
  final bool storeUnavailable;
}
