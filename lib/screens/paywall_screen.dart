import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/home_screen.dart';
import 'package:authenticator/screens/settings_screen.dart';
import 'package:authenticator/widgets/primary_button.dart';
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

  static const List<_Plan> _plans = [
    _Plan(
      title: 'Weekly',
      subtitle: 'Billed every week',
      price: '\$2.49',
      period: '/wk',
      badge: '3 days free trial',
    ),
    _Plan(
      title: 'Monthly',
      subtitle: 'Billed every month',
      price: '\$4.99',
      period: '/mo',
    ),
    _Plan(
      title: 'Yearly',
      subtitle: 'Billed annually',
      price: '\$39.99',
      period: '/yr',
      highlight: 'Save 33%',
    ),
  ];

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
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
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
                            "Continue",
                            style: AppTextStyles.bodyMediumSemiBold.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
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
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: AppColors.black),
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
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Text(
                  plan.title,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          if (plan.highlight != null) ...[
            Text(
              plan.highlight!,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.orange500,
              ),
            ),
            const SizedBox(width: 8),
          ],
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
