import 'dart:math';

import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/password_local_data_source.dart';
import 'package:authenticator/models/password_entry.dart';
import 'package:authenticator/widgets/custom_toast.dart';
import 'package:flutter/material.dart';

/// Screen for adding a new password entry, with an optional built-in
/// password generator and a live strength indicator.
///
/// When [entry] and [editIndex] are provided the screen operates in "edit"
/// mode: the fields are pre-filled and saving updates the existing entry in
/// place instead of appending a new one.
class AddPasswordScreen extends StatefulWidget {
  /// Existing entry to edit. When null the screen adds a new password.
  final PasswordEntry? entry;

  /// Index of [entry] within the stored list, used when persisting an edit.
  final int? editIndex;

  const AddPasswordScreen({super.key, this.entry, this.editIndex});

  bool get isEditing => entry != null && editIndex != null;

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Local data source used to persist passwords in SharedPreferences.
  final PasswordLocalDataSource _dataSource =
      SharedPrefsPasswordLocalDataSource();

  bool _obscurePassword = true;
  bool _showGenerator = false;
  bool _saving = false;

  // Generator options.
  double _length = 15;
  bool _includeUpper = true;
  bool _includeDigits = true;
  bool _includeSymbols = true;
  String _generated = '';

  bool get _canSave =>
      _serviceController.text.trim().isNotEmpty &&
      _accountController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _serviceController.text = entry.service;
      _accountController.text = entry.account;
      _passwordController.text = entry.password;
    }
    _serviceController.addListener(_onChanged);
    _accountController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
    _generated = _buildPassword();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _serviceController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleGenerator() => setState(() => _showGenerator = !_showGenerator);

  String _buildPassword() {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*+-=';

    var pool = lower;
    if (_includeUpper) pool += upper;
    if (_includeDigits) pool += digits;
    if (_includeSymbols) pool += symbols;

    final rand = Random.secure();
    final len = _length.round();
    return List.generate(len, (_) => pool[rand.nextInt(pool.length)]).join();
  }

  void _regenerate() => setState(() => _generated = _buildPassword());

  void _useGeneratedPassword() {
    setState(() {
      _passwordController.text = _generated;
      _obscurePassword = false;
      _showGenerator = false;
    });
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final service = _serviceController.text.trim();
    final entry = PasswordEntry(
      service: service,
      account: _accountController.text.trim(),
      password: _passwordController.text,
    );

    final bool editing = widget.isEditing;
    if (editing) {
      await _dataSource.updatePassword(widget.editIndex!, entry);
    } else {
      await _dataSource.addPassword(entry);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
    CustomToast.show(
      context,
      message: editing
          ? '$service password updated'
          : '$service password saved',
    );
  }

  /// Strength on a 0..1 scale from length + character variety.
  double get _strength {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) return 0;
    var score = 0.0;
    if (pwd.length >= 8) score += 0.25;
    if (pwd.length >= 12) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) score += 0.20;
    return score.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = _passwordController.text.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black,
            size: 20,
          ),
        ),
        title: Text(
          widget.isEditing ? 'Edit Password' : 'Add Password',
          style: AppTextStyles.h2.copyWith(color: AppColors.black),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SaveButton(enabled: _canSave && !_saving, onTap: _save),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Service Name'),
              const SizedBox(height: 8),
              _InputField(
                controller: _serviceController,
                hintText: 'GitHub, Google, Stripe...',
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Account / Email'),
              const SizedBox(height: 8),
              _InputField(
                controller: _accountController,
                hintText: 'alice@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Password'),
              const SizedBox(height: 8),
              _PasswordField(
                controller: _passwordController,
                obscure: _obscurePassword,
                showLock: hasPassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              if (hasPassword) ...[
                const SizedBox(height: 12),
                _StrengthBar(strength: _strength),
              ],
              const SizedBox(height: 16),
              _GeneratorToggle(
                showing: _showGenerator,
                onTap: _toggleGenerator,
              ),
              if (_showGenerator) ...[
                const SizedBox(height: 16),
                _GeneratorCard(
                  password: _generated,
                  length: _length,
                  includeUpper: _includeUpper,
                  includeDigits: _includeDigits,
                  includeSymbols: _includeSymbols,
                  onRegenerate: _regenerate,
                  onLengthChanged: (v) => setState(() {
                    _length = v;
                    _generated = _buildPassword();
                  }),
                  onToggleUpper: () => setState(() {
                    _includeUpper = !_includeUpper;
                    _generated = _buildPassword();
                  }),
                  onToggleDigits: () => setState(() {
                    _includeDigits = !_includeDigits;
                    _generated = _buildPassword();
                  }),
                  onToggleSymbols: () => setState(() {
                    _includeSymbols = !_includeSymbols;
                    _generated = _buildPassword();
                  }),
                  onUse: _useGeneratedPassword,
                ),
              ],
              const SizedBox(height: 16),
              const _InfoNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SaveButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.orange500 : AppColors.gray200,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Text(
            'Save',
            style: AppTextStyles.bodyMediumSemiBold.copyWith(
              color: enabled ? AppColors.white : AppColors.gray400,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
        },
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool showLock;
  final VoidCallback onToggleObscure;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.showLock,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showLock) ...[
            const Icon(Icons.lock_outline, size: 18, color: AppColors.gray500),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              obscuringCharacter: 'x',
              style: AppTextStyles.numberMedium.copyWith(
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'xxxxxx',
                hintStyle: AppTextStyles.numberMedium.copyWith(
                  color: AppColors.gray500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onToggleObscure,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final double strength; // 0..1

  const _StrengthBar({required this.strength});

  ({String label, Color color, int segments}) get _info {
    if (strength >= 0.8) {
      return (label: 'Strong', color: AppColors.success, segments: 3);
    }
    if (strength >= 0.5) {
      return (label: 'Medium', color: AppColors.orange500, segments: 2);
    }
    return (label: 'Weak', color: AppColors.error, segments: 1);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (i) {
              final active = i < info.segments;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: active ? info.color : AppColors.gray200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          info.label,
          style: AppTextStyles.bodySmallSemiBold.copyWith(color: info.color),
        ),
      ],
    );
  }
}

class _GeneratorToggle extends StatelessWidget {
  final bool showing;
  final VoidCallback onTap;

  const _GeneratorToggle({required this.showing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.autorenew, size: 20, color: AppColors.orange500),
          const SizedBox(width: 8),
          Text(
            showing ? 'Hide generator' : 'Generate password',
            style: AppTextStyles.bodyMediumSemiBold.copyWith(
              color: AppColors.orange500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  final String password;
  final double length;
  final bool includeUpper;
  final bool includeDigits;
  final bool includeSymbols;
  final VoidCallback onRegenerate;
  final ValueChanged<double> onLengthChanged;
  final VoidCallback onToggleUpper;
  final VoidCallback onToggleDigits;
  final VoidCallback onToggleSymbols;
  final VoidCallback onUse;

  const _GeneratorCard({
    required this.password,
    required this.length,
    required this.includeUpper,
    required this.includeDigits,
    required this.includeSymbols,
    required this.onRegenerate,
    required this.onLengthChanged,
    required this.onToggleUpper,
    required this.onToggleDigits,
    required this.onToggleSymbols,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange500.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    password,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.numberMedium.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onRegenerate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.autorenew,
                    size: 22,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.orange500,
              inactiveTrackColor: AppColors.gray200,
              thumbColor: AppColors.white,
              overlayColor: AppColors.orange500.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 2,
              ),
            ),
            child: Slider(
              min: 8,
              max: 32,
              value: length,
              onChanged: onLengthChanged,
            ),
          ),
          Row(
            children: [
              Text(
                '8',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${length.round()} chars',
                    style: AppTextStyles.bodySmallSemiBold.copyWith(
                      color: AppColors.orange500,
                    ),
                  ),
                ),
              ),
              Text(
                '32',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OptionChip(
                  label: 'A-Z',
                  active: includeUpper,
                  onTap: onToggleUpper,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionChip(
                  label: '0-9',
                  active: includeDigits,
                  onTap: onToggleDigits,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionChip(
                  label: '!@#',
                  active: includeSymbols,
                  onTap: onToggleSymbols,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.orange500,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onUse,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Use this password',
                      style: AppTextStyles.bodyMediumSemiBold.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.orange400 : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMediumSemiBold.copyWith(
            color: active ? AppColors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.gray500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Passwords are encrypted with AES-256 and '
              'stored only on this device.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
