import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';

class SetPasscodeScreen extends StatefulWidget {
  const SetPasscodeScreen({super.key});

  @override
  State<SetPasscodeScreen> createState() => _SetPasscodeScreenState();
}

class _SetPasscodeScreenState extends State<SetPasscodeScreen> {
  static const int _length = 4;
  String _passcode = '';
  String? _firstPasscode;
  bool _confirming = false;
  bool _error = false;

  void _onDigit(String d) {
    if (_passcode.length >= _length) return;
    setState(() {
      _passcode += d;
      _error = false;
    });
    if (_passcode.length == _length) {
      Future.delayed(const Duration(milliseconds: 200), _onComplete);
    }
  }

  void _onComplete() {
    if (!mounted) return;
    if (!_confirming) {
      // First entry done — move to the confirmation step.
      setState(() {
        _firstPasscode = _passcode;
        _confirming = true;
        _passcode = '';
      });
    } else {
      if (_passcode == _firstPasscode) {
        Navigator.of(context).pop(_passcode);
      } else {
        // Mismatch — restart from the beginning.
        setState(() {
          _error = true;
          _confirming = false;
          _firstPasscode = null;
          _passcode = '';
        });
      }
    }
  }

  void _onDelete() {
    if (_passcode.isEmpty) return;
    setState(() => _passcode = _passcode.substring(0, _passcode.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Set Passcode',
          style: AppTextStyles.h3.copyWith(color: AppColors.black),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              _confirming ? 'Re-enter to confirm' : 'Create a passcode',
              style: AppTextStyles.bodyMediumSemiBold.copyWith(
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 28),
            _PasscodeDots(
              length: _length,
              filled: _passcode.length,
              error: _error,
            ),
            if (_error) ...[
              const SizedBox(height: 16),
              Text(
                'Passcodes didn\'t match. Try again',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ],
            const Spacer(),

            _Keypad(onDigit: _onDigit, onDelete: _onDelete),
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
  final bool error;

  const _PasscodeDots({
    required this.length,
    required this.filled,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = error ? AppColors.error : AppColors.orange500;
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
            color: isFilled ? activeColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? activeColor : AppColors.gray300,
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

  const _Keypad({required this.onDigit, required this.onDelete});

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
              const Expanded(child: SizedBox()),
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
