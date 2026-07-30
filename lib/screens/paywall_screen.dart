import 'dart:async';

import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/home_screen.dart';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:authenticator/services/adapty_service.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0;
  bool _showCloseButton = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _closeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showCloseButton = true);
      }
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  final AdaptyService _adapty = AdaptyService.instance;

  /// Products fetched from the Adapty paywall. Empty while loading or when the
  /// fetch failed (in which case we fall back to the static placeholders).
  List<AdaptyPaywallProduct> _products = const [];
  bool _purchasing = false;

  /// `true` once a load attempt finished without any purchasable product
  /// (misconfigured / unavailable store — Adapty error 1000). Distinguishes
  /// "unavailable" from "still loading" in the [_onContinue] message.
  bool _storeUnavailable = false;

  /// Plans rendered by the UI — derived from the live Adapty products when
  /// available, otherwise the static [_fallbackPlans].
  List<_Plan> get _plans {
    return _products.map(_planFromProduct).toList(growable: false);
  }

  _Plan _planFromProduct(AdaptyPaywallProduct product) {
    final period = product.subscription?.period;
    final hasTrial =
        product.subscription?.offer?.phases.any(
          (p) => p.paymentMode == AdaptyPaymentMode.freeTrial,
        ) ??
        false;
    return _Plan(
      title: product.localizedTitle,
      subtitle: product.localizedDescription,
      price: "${product.price.currencySymbol}${product.price.amount}",
      period: period == null ? '' : '/${_periodSuffix(period.unit)}',
      badge: hasTrial ? 'Free trial' : null,
      highlight: product.subscription?.period.unit == AdaptyPeriodUnit.year
          ? "Save 33%"
          : null,
    );
  }

  String _periodSuffix(AdaptyPeriodUnit unit) {
    switch (unit) {
      case AdaptyPeriodUnit.day:
        return 'day';
      case AdaptyPeriodUnit.week:
        return 'wk';
      case AdaptyPeriodUnit.month:
        return 'mo';
      case AdaptyPeriodUnit.year:
        return 'yr';
      case AdaptyPeriodUnit.unknown:
        return '';
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _adapty.loadPaywall();
      if (!mounted) return;
      setState(() {
        _products = data.products;
        _storeUnavailable = data.storeUnavailable;
        if (_selectedPlan >= _products.length && _products.isNotEmpty) {
          _selectedPlan = 0;
        }
      });
    } catch (_) {
      // Keep the static fallback plans visible if the fetch fails, but allow
      // "Continue" to retry rather than reporting the store as unavailable.
      if (mounted) setState(() => _storeUnavailable = false);
    }
  }

  Future<void> _onContinue() async {
    if (_purchasing) return;
    // The static fallback tiles are on screen both while the live products are
    // still loading and if the fetch failed, so `_selectedPlan` can point past
    // the end of an empty `_products`. Retry the fetch instead of indexing into
    // it (RangeError) — and without waving the user through for free.
    if (_products.isEmpty) {
      _showMessage(
        _storeUnavailable
            ? 'Subscriptions are unavailable right now. Please try again later.'
            : 'Plans are still loading. Please try again in a moment.',
      );
      unawaited(_loadProducts());
      return;
    }
    setState(() => _purchasing = true);
    try {
      final unlocked = await _adapty.purchase(_products[_selectedPlan]);
      if (!mounted) return;
      if (unlocked) {
        _goToHome();
      }
    } catch (e) {
      _showMessage('Purchase failed. Please try again.');
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _onRestore() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final unlocked = await _adapty.restore();
      if (!mounted) return;
      if (unlocked) {
        _goToHome();
      } else {
        _showMessage('No active subscription to restore.');
      }
    } catch (_) {
      _showMessage('Restore failed. Please try again.');
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Dismisses the paywall. Since the paywall replaces the splash screen (there
  /// is no route underneath to pop back to), closing it should take the user
  /// into the app rather than doing nothing.
  void _onClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _goToHome();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            "assets/images/shield.png",
                            height: 138,
                          ),
                        ),
                        Text(
                          'Unlock full protection for your accounts',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Start your free trial, then just \$2.49/week.\nCancel anytime',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _FeatureRow(
                          icon: 'assets/svg/Icon1.svg',
                          title: 'Unlimited 2FA accounts',
                          subtitle: 'All your codes secured in one place',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureRow(
                          icon: 'assets/svg/icon2.svg',
                          title: 'AI-generated strong passwords',
                          subtitle: 'Unique passwords instantly',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureRow(
                          icon: 'assets/svg/icon3.svg',
                          title: 'Private browsing with no history',
                          subtitle: 'Session cleared automatically on exit',
                        ),
                        const SizedBox(height: 24),
                        for (int i = 0; i < _plans.length; i++) ...[
                          _PlanTile(
                            plan: _plans[i],
                            selected: _selectedPlan == i,
                            onTap: () => setState(() => _selectedPlan = i),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16,
                              offset: Offset(0, 4),
                              color: AppColors.orange500.withAlpha(150),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _purchasing ? null : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange500,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.orange500,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: _purchasing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  "Continue",
                                  style: AppTextStyles.bodyMediumSemiBold
                                      .copyWith(color: AppColors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'By continuing, you agree to:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.black,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    _openUrl('https://www.google.com'),
                            ),
                            TextSpan(
                              text: ' & ',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                            TextSpan(
                              text: 'Terms of Use',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.black,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    _openUrl('https://www.facebook.com'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showCloseButton)
              Align(
                alignment: Alignment.topLeft,
                child: AnimatedOpacity(
                  opacity: _showCloseButton ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showCloseButton,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _onClose,
                      icon: const Icon(Icons.close, color: AppColors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final String? badge;
  final String? highlight;

  const _Plan({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    this.badge,
    this.highlight,
  });
}

class _PlanTile extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print(plan);
    print("object");
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.orange500 : AppColors.gray200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.title,
                      style: AppTextStyles.bodySmallSemiBold.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    if (plan.highlight != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: AppColors.orange50,
                        ),
                        child: Text(
                          plan.highlight ?? '',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.orange500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  plan.subtitle,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),

          RichText(
            text: TextSpan(
              text: plan.price,
              style: AppTextStyles.bodyMediumSemiBold.copyWith(
                color: AppColors.black,
              ),
              children: [
                TextSpan(
                  text: plan.period,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: plan.badge == null
          ? tile
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(padding: const EdgeInsets.only(top: 10), child: tile),
                Positioned(
                  top: 0,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange500,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: Offset(0, 3),
                          color: AppColors.orange500.withAlpha(150),
                        ),
                      ],
                    ),
                    child: Text(
                      plan.badge ?? '',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: selected ? AppColors.orange600 : AppColors.gray300,
            ),
          ),
        ),
        if (selected)
          Positioned.fill(
            child: Center(
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(Icons.check_circle, color: AppColors.orange500),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange50,
              borderRadius: BorderRadius.circular(100),
            ),
            child: SvgPicture.asset(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmallSemiBold.copyWith(
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
