import 'package:authenticator/services/purchase_service.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the app must be hard-gated behind the paywall.
///
/// The rule: as long as the user has **not bought a subscription** (their
/// introductory offer / trial has run out or was never started), every tap
/// inside the app brings the paywall back. An active subscription unlocks the
/// app completely.
///
/// A [ChangeNotifier] singleton so any widget (currently `PaywallGate`) can
/// listen, and so the state can be refreshed from anywhere: after a purchase,
/// after a restore, and whenever the app returns to the foreground.
class AccessGate extends ChangeNotifier {
  AccessGate({PurchaseService? purchaseService})
    : _purchaseService = purchaseService ?? AdaptyPurchaseService();

  /// Singleton used by the UI.
  static final AccessGate instance = AccessGate();

  final PurchaseService _purchaseService;

  bool _locked = false;
  bool _refreshing = false;

  /// `true` when there is no active subscription — the UI must present the
  /// paywall on every interaction.
  bool get isLocked => _locked;

  /// Re-evaluates the gate against the store.
  ///
  /// Never throws, and an unknown answer (network / SDK failure) keeps the
  /// previous state instead of locking a paying user out.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final subscribed = await _purchaseService.hasActiveSubscription();
      _setLocked(!subscribed);
    } catch (e) {
      debugPrint('AccessGate: refresh failed, keeping locked=$_locked ($e)');
    } finally {
      _refreshing = false;
    }
  }

  /// Immediately unlocks the app — call right after a successful purchase or
  /// restore so the user isn't gated while the store profile propagates.
  void unlock() => _setLocked(false);

  void _setLocked(bool value) {
    if (_locked == value) return;
    _locked = value;
    notifyListeners();
  }
}
