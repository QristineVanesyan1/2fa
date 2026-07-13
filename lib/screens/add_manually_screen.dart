import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/account_local_data_source.dart';
import 'package:authenticator/models/account.dart';
import 'package:authenticator/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen for manually adding a 2FA account by typing the secret key.
class AddManuallyScreen extends StatefulWidget {
  final String? initialService;
  final String? initialAccount;
  final String? initialSecret;

  const AddManuallyScreen({
    super.key,
    this.initialService,
    this.initialAccount,
    this.initialSecret,
  });

  @override
  State<AddManuallyScreen> createState() => _AddManuallyScreenState();
}

class _AddManuallyScreenState extends State<AddManuallyScreen> {
  late final TextEditingController _serviceController = TextEditingController(
    text: widget.initialService,
  );
  late final TextEditingController _accountController = TextEditingController(
    text: widget.initialAccount,
  );
  late final TextEditingController _secretController = TextEditingController(
    text: widget.initialSecret,
  );

  // Local data source used to persist accounts in SharedPreferences.
  final AccountLocalDataSource _dataSource =
      SharedPrefsAccountLocalDataSource();

  // Palette used to give each new account a stable avatar color.
  static const _avatarColors = <Color>[
    AppColors.black,
    AppColors.orange500,
    AppColors.blue,
    AppColors.orange400,
    AppColors.red,
    AppColors.teal,
  ];

  bool _obscureSecret = true;
  bool _saving = false;

  bool get _canSave =>
      _serviceController.text.trim().isNotEmpty &&
      _accountController.text.trim().isNotEmpty &&
      _secretController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _serviceController.addListener(_onChanged);
    _accountController.addListener(_onChanged);
    _secretController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _serviceController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _pasteSecret() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _secretController.text = text;
      _secretController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    }
  }

  Color _colorForService(String service) {
    final hash = service.toLowerCase().codeUnits.fold<int>(
      0,
      (acc, c) => acc + c,
    );
    return _avatarColors[hash % _avatarColors.length];
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final service = _serviceController.text.trim();
    final account = Account(
      name: service,
      issuerEmail: _accountController.text.trim(),
      secret: _secretController.text.trim(),
      avatarColor: _colorForService(service),
    );
    await _dataSource.addAccount(account);

    if (!mounted) return;
    Navigator.of(context).pop();
    CustomToast.show(context, message: '$service added');
  }

  @override
  Widget build(BuildContext context) {
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
          'Add Manually',
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
              const _FieldLabel('Secret Key'),
              const SizedBox(height: 8),
              _SecretField(
                controller: _secretController,
                obscure: _obscureSecret,
                onPaste: _pasteSecret,
                onToggleObscure: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
              ),
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

class _SecretField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onPaste;
  final VoidCallback onToggleObscure;

  const _SecretField({
    required this.controller,
    required this.obscure,
    required this.onPaste,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (hasText) ...[
            const Icon(Icons.lock_outline, size: 18, color: AppColors.gray500),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              obscureText: obscure && hasText,
              obscuringCharacter: '•',
              style: AppTextStyles.numberMedium.copyWith(
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Base32 encoded secret',
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
          if (hasText)
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
            )
          else
            GestureDetector(
              onTap: onPaste,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Paste',
                style: AppTextStyles.bodyMediumSemiBold.copyWith(
                  color: AppColors.orange500,
                ),
              ),
            ),
        ],
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
              'Your secret key is encrypted and stored only on '
              'this device. It is never shared.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
