import 'package:authenticator/screens/paywall_screen.dart';
import 'package:authenticator/services/access_gate.dart';
import 'package:flutter/material.dart';

/// Wraps the app's content and presents the paywall on **every tap** while no
/// subscription has been bought (i.e. the introductory offer / free trial has
/// run out or was never started).

///
/// Implemented with a [Listener] on the pointer-down phase rather than a
/// [GestureDetector] so the paywall opens before the underlying widget can
/// react — the tap is swallowed and never reaches the gated UI.
class PaywallGate extends StatefulWidget {
  const PaywallGate({super.key, required this.child, this.gate});

  final Widget child;

  /// Injectable for tests; defaults to the app-wide [AccessGate.instance].
  final AccessGate? gate;

  @override
  State<PaywallGate> createState() => _PaywallGateState();
}

class _PaywallGateState extends State<PaywallGate> with WidgetsBindingObserver {
  AccessGate get _gate => widget.gate ?? AccessGate.instance;

  /// Guards against pushing several paywalls for one burst of pointers.
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gate.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A subscription may have been bought / cancelled outside the app.
    if (state == AppLifecycleState.resumed) _gate.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _presentPaywall() async {
    if (_presenting || !_gate.isLocked) return;
    _presenting = true;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
    if (!mounted) {
      _presenting = false;
      return;
    }
    // Re-check after the paywall is dismissed: if the user subscribed the gate
    // opens up, otherwise the next tap brings it straight back.
    await _gate.refresh();
    _presenting = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gate,
      builder: (context, _) {
        if (!_gate.isLocked) return widget.child;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _presentPaywall(),
          // Block the gated UI from receiving the gesture at all.
          child: AbsorbPointer(child: widget.child),
        );
      },
      child: widget.child,
    );
  }
}
