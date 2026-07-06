import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      // Hand control back to the startup flow (SplashScreen), which persists
      // onboarding completion and then runs the subscription check.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _OnboardingPage(
                    illustration: _OnboardingIllustrationOne(),
                    title: 'All your 2FA codes, in\none safe place.',
                    subtitle:
                        'Protect every account with one-tap authenticator '
                        'codes, always within reach.',
                  ),
                  _OnboardingPage(
                    illustration: _OnboardingIllustrationTwo(),
                    title: 'Generate, store, and\nbrowse — all protected.',
                    subtitle:
                        'Strong passwords. Private sessions. One app, zero '
                        'compromises.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PageIndicator(count: 2, active: _page),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: _PrimaryButton(
                  label: _page == 0 ? 'Next' : 'Get started',
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(width: double.infinity, child: illustration),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: AppColors.base,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h1.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingIllustrationOne extends StatelessWidget {
  const _OnboardingIllustrationOne();

  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/images/onboarding.png", fit: BoxFit.cover);
  }
}

class _OnboardingIllustrationTwo extends StatelessWidget {
  const _OnboardingIllustrationTwo();

  @override
  Widget build(BuildContext context) {
    return Image.asset("assets/images/onboarding2.png", fit: BoxFit.cover);
  }
}

class _ShieldBadge extends StatelessWidget {
  final String icon;
  final double size;

  const _ShieldBadge({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(icon);
  }
}

class _AppBubble extends StatelessWidget {
  final Color color;
  final String label;

  const _AppBubble({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.h3.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PasswordChip extends StatelessWidget {
  final double strength;
  final String label;
  final Color color;
  final String? text;

  const _PasswordChip({
    required this.strength,
    required this.label,
    required this.color,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text ?? '••••••••••••••',
                  style: AppTextStyles.numberMedium.copyWith(
                    color: AppColors.gray800,
                  ),
                ),
              ),
              const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: AppColors.gray500,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 5,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int active;

  const _PageIndicator({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 22 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.orange500 : AppColors.gray300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange500,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMediumSemiBold.copyWith(
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
