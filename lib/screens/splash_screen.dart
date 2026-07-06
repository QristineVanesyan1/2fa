import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/home_screen.dart';
import 'package:authenticator/screens/onboarding_screen.dart';
import 'package:authenticator/screens/paywall_screen.dart';
import 'package:authenticator/startup/app_startup_coordinator.dart';
import 'package:flutter/material.dart';

/// Splash / preloader shown immediately on launch.
///
/// It stays visible while the [AppStartupCoordinator] runs the startup checks
/// (onboarding + entitlement) and then navigates exactly once to the resolved
/// destination. If a check fails it shows an inline retry state instead of
/// leaving the user on a blank screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.coordinator});

  final AppStartupCoordinator coordinator;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

enum _Phase { loading, error }

class _SplashScreenState extends State<SplashScreen> {
  _Phase _phase = _Phase.loading;

  /// Guards against re-entrancy / duplicate navigation.
  bool _running = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartup());
  }

  Future<void> _runStartup() async {
    if (_running || _navigated) return;
    _running = true;
    if (mounted) setState(() => _phase = _Phase.loading);

    try {
      final destination = await widget.coordinator.resolveInitialDestination();
      await _goTo(destination);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.error);
    } finally {
      _running = false;
    }
  }

  Future<void> _goTo(StartupDestination destination) async {
    if (!mounted || _navigated) return;

    switch (destination) {
      case StartupDestination.onboarding:
        // Show onboarding on top of the splash. When it returns we persist
        // completion and continue with the entitlement check. Errors here
        // bubble up to _runStartup's catch so we still show a retry state.
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        final next = await widget.coordinator.completeOnboardingAndResolve();
        await _goTo(next);
        break;

      case StartupDestination.home:
        _replaceWith(const HomeScreen());
        break;

      case StartupDestination.paywall:
        _replaceWith(const PaywallScreen());
        break;
    }
  }

  void _replaceWith(Widget screen) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: Center(
        child: _phase == _Phase.loading
            ? const _LoadingView()
            : _ErrorView(onRetry: _runStartup),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _BrandBadge(),
        SizedBox(height: 28),
        SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation(AppColors.orange500),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandBadge(),
          const SizedBox(height: 28),
          Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t finish getting things ready. '
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onRetry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange500,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.bodyMediumSemiBold.copyWith(
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

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange400, AppColors.orange500],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange500.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.lock, color: AppColors.white, size: 44),
    );
  }
}
