import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centered empty-state placeholder shared by the Codes and Passwords screens.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.orange500.withValues(alpha: 0.18),
                  AppColors.orange500.withValues(alpha: 0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(icon),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.black)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
