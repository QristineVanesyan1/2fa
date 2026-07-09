import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/services/app_lock_service.dart';
import 'package:authenticator/services/biometric_auth.dart';
import 'package:authenticator/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Full-screen lock that must be cleared (via passcode or Face ID) before the
/// user can reach the rest of the app. Shown on launch whenever a passcode
/// and/or Face ID has been enabled in Settings.
///
/// Calls [onUnlocked] exactly once when authentication succeeds.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.appLockService,
    required this.onUnlocked,
  });

  final AppLockService appLockService;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const int _length = 4;

  String _entered = '';
  String? _storedPasscode;
  bool _passcodeEnabled = false;
  bool _faceIdEnabled = false;
  bool _loading = true;
  bool _error = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final passcodeEnabled = await widget.appLockService.isPasscodeEnabled();
    final faceIdEnabled = await widget.appLockService.isFaceIdEnabled();
    final passcode = await widget.appLockService.getPasscode();
    if (!mounted) return;
    setState(() {
      _passcodeEnabled = passcodeEnabled;
      _faceIdEnabled = faceIdEnabled;
      _storedPasscode = passcode;
      _loading = false;
    });

    // Prefer Face ID automatically when it's enabled.
    if (_faceIdEnabled) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_authenticating) return;
    _authenticating = true;
    final result = await BiometricAuth.authenticate(reason: 'Unlock the app');
    _authenticating = false;
    if (!mounted) return;
    if (result.success) {
      widget.onUnlocked();
    } else if (result.error != null && !_passcodeEnabled) {
      // If there is no passcode fallback, surface the error so the user can
      // retry biometrics.
      CustomToast.show(context, message: result.error!, success: false);
    }
  }

  void _onDigit(String d) {
    if (_entered.length >= _length) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == _length) {
      _verify();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _verify() {
    if (_entered == _storedPasscode) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.base,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.orange500),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Image.asset('assets/images/shield.png', height: 160),
            Text(
              'Enter Passcode',
              style: AppTextStyles.h3.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _error ? 'Incorrect passcode. Try again.' : 'Unlock to continue',
              style: AppTextStyles.bodySmall.copyWith(
                color: _error ? AppColors.error : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 28),
            _PasscodeDots(length: _length, filled: _entered.length),
            const Spacer(),
            if (_passcodeEnabled)
              _Keypad(
                onDigit: _onDigit,
                onDelete: _onDelete,
                showBiometric: _faceIdEnabled,
                onBiometric: _authenticateWithBiometrics,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      'Unlock with Face ID',
                      style: AppTextStyles.bodyMediumSemiBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PasscodeDots extends StatelessWidget {
  final int length;
  final int filled;

  const _PasscodeDots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.orange500 : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.orange500 : AppColors.gray300,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool showBiometric;
  final VoidCallback onBiometric;

  const _Keypad({
    required this.onDigit,
    required this.onDelete,
    required this.showBiometric,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 16),
          _row(['4', '5', '6']),
          const SizedBox(height: 16),
          _row(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: showBiometric
                    ? _KeyButton(
                        onTap: onBiometric,
                        background: AppColors.gray200,
                        child: const Icon(
                          Icons.fingerprint,
                          size: 26,
                          color: AppColors.black,
                        ),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KeyButton(label: '0', onTap: () => onDigit('0')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KeyButton(
                  onTap: onDelete,
                  background: AppColors.gray200,
                  child: const Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(
            child: _KeyButton(
              label: digits[i],
              onTap: () => onDigit(digits[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onTap;
  final Color background;

  const _KeyButton({
    this.label,
    this.child,
    required this.onTap,
    this.background = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 72,
          child: Center(
            child:
                child ??
                Text(
                  label ?? '',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
