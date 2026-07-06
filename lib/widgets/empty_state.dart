import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';

/// Centered empty-state placeholder shared by the Codes and Passwords screens.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

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
            height: 120,
            width: 120,
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
            child: Icon(icon, size: 64, color: AppColors.orange500),
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
