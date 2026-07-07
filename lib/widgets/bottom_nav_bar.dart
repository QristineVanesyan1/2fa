import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared bottom navigation bar used by the home shell (and any other screen
/// that needs to show the same tab bar).
class BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const BottomNavBar({super.key, required this.index, required this.onChanged});

  static const items = [
    ("assets/svg/Auth.svg", 'Codes'),
    ("assets/svg/Password.svg", 'Passwords'),
    ("assets/svg/Browser.svg", 'Browser'),
    ("assets/svg/Settings.svg", 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gray800,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == index;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          item.$1,
                          colorFilter: ColorFilter.mode(
                            active ? AppColors.black : AppColors.gray400,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: AppTextStyles.caption.copyWith(
                            color: active ? AppColors.black : AppColors.gray400,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
