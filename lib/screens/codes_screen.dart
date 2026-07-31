import 'dart:async';

import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/account_local_data_source.dart';
import 'package:authenticator/models/account.dart';
import 'package:authenticator/screens/add_manually_screen.dart';
import 'package:authenticator/screens/scan_qr_screen.dart';
import 'package:authenticator/services/totp_service.dart';
import 'package:authenticator/widgets/custom_toast.dart';
import 'package:authenticator/widgets/empty_state.dart';
import 'package:authenticator/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

/// How the user chose to add a new account from the add-account sheet.
enum _AddMethod { scan, manual }

/// Actions the account detail bottom sheet can return to its opener.
enum _DetailAction { edit, copy, delete }

/// Standalone Codes tab: lists TOTP accounts with a live countdown and lets the
/// user add more accounts.
class CodesScreen extends StatefulWidget {
  /// When true the screen renders the empty ("Nothing here yet") state.
  final bool showEmpty;

  const CodesScreen({super.key, this.showEmpty = false});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AccountLocalDataSource _accountsDataSource =
      SharedPrefsAccountLocalDataSource();

  String _query = '';
  List<Account> _accounts = [];

  // Countdown seconds shared by every code (TOTP style 30s window).
  int _remaining = TotpService.secondsRemaining();
  Timer? _timer;

  /// Returns the live 6-digit TOTP code for [account], formatted for display.
  /// Falls back to any stored [Account.code] when no secret is available.
  String _codeFor(Account account) {
    if (account.secret.trim().isEmpty) {
      return account.code.isNotEmpty ? account.code : '------';
    }
    return TotpService.generateFormatted(account.secret);
  }

  List<Account> get _filtered {
    if (_query.isEmpty) return _accounts;
    final q = _query.toLowerCase();
    return _accounts
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              a.issuerEmail.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    // Tick every second, syncing the countdown to the real TOTP window so the
    // displayed codes rotate exactly when they expire.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = TotpService.secondsRemaining());
    });
  }

  // Signatures of the old static demo accounts ("name|issuerEmail|code"),
  // which carried a hard-coded code and no secret. They are migrated to demo
  // accounts backed by real TOTP secrets so codes actually rotate.

  // Demo accounts backed by real Base32 secrets so the generated codes rotate
  // every 30 seconds, exactly like Google Authenticator.

  Future<void> _load() async {
    if (widget.showEmpty) {
      if (!mounted) return;
      setState(() => _accounts = []);
      return;
    }
    var accounts = await _accountsDataSource.getAccounts();

    // Migrate away from the old static demo accounts (code, but no secret).

    // Seed the secret-backed demo accounts on a fresh install so the tab shows
    // live, rotating codes out of the box.

    if (!mounted) return;
    setState(() => _accounts = accounts);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddAccountSheet() async {
    // The sheet only reports which method the user picked; the actual
    // navigation happens here so we can await it and reload afterwards.
    final method = await showModalBottomSheet<_AddMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddAccountSheet(),
    );
    if (!mounted || method == null) return;

    switch (method) {
      case _AddMethod.scan:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ScanQrScreen()));
        break;
      case _AddMethod.manual:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddManuallyScreen()),
        );
        break;
    }

    if (!mounted) return;
    // Reload so any account persisted during the add flow shows up here.
    await _load();
  }

  void _copyCode(Account account) {
    final code = _codeFor(account).replaceAll(' ', '');
    Clipboard.setData(ClipboardData(text: code));
    CustomToast.show(context, message: '${account.name} code copied');
  }

  /// Opens the detail bottom sheet for [account].
  ///
  /// The sheet shows the live code with a large countdown ring and exposes
  /// Edit / Copy / Delete actions. Because filtering can reorder the visible
  /// list, the account's real index in [_accounts] is resolved before mutating.
  Future<void> _openDetails(Account account) async {
    final action = await showModalBottomSheet<_DetailAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AccountDetailSheet(account: account),
    );

    if (!mounted || action == null) return;

    final index = _accounts.indexOf(account);
    if (index < 0) return;

    switch (action) {
      case _DetailAction.copy:
        _copyCode(account);
        break;
      case _DetailAction.edit:
        await _editAccount(account, index);
        break;
      case _DetailAction.delete:
        await _confirmDelete(account, index);
        break;
    }
  }

  Future<void> _editAccount(Account account, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddManuallyScreen(
          initialService: account.name,
          initialAccount: account.issuerEmail,
          initialSecret: account.secret,
          editIndex: index,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmDelete(Account account, int index) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.overlay,
      builder: (_) => _DeleteAccountSheet(account: account),
    );

    if (!mounted || confirmed != true) return;

    await _accountsDataSource.deleteAccount(index);
    await _load();
    if (!mounted) return;
    CustomToast.show(context, message: '${account.name} deleted');
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filtered;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.base,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountSheet,

        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 30),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authenticator',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_accounts.length} accounts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SearchField(
                    controller: _searchController,
                    hintText: 'Search accounts...',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: accounts.isEmpty
                  ? EmptyState(
                      title: 'Nothing here yet',
                      subtitle:
                          'Add your first account manually or scan a QR code',
                      icon: "assets/images/empty1.png",
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.gray200,
                        ),
                      ),
                      itemBuilder: (_, i) => _AccountRow(
                        account: accounts[i],
                        code: _codeFor(accounts[i]),
                        remaining: _remaining,
                        onCopy: () => _copyCode(accounts[i]),
                        onTap: () => _openDetails(accounts[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final String code;
  final int remaining;
  final VoidCallback onCopy;
  final VoidCallback onTap;

  const _AccountRow({
    required this.account,
    required this.code,
    required this.remaining,
    required this.onCopy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: account.avatarColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                account.initial,
                style: AppTextStyles.bodyMediumSemiBold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTextStyles.bodyMediumSemiBold.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.issuerEmail,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              code,
              style: AppTextStyles.numberLarge.copyWith(color: AppColors.black),
            ),
            const SizedBox(width: 10),
            _CountdownRing(remaining: remaining),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCopy,
              visualDensity: VisualDensity.compact,
              icon: SvgPicture.asset("assets/svg/Copy.svg"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing a single account's live code with a large countdown
/// ring and Edit / Copy / Delete actions.
class _AccountDetailSheet extends StatefulWidget {
  final Account account;

  const _AccountDetailSheet({required this.account});

  @override
  State<_AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends State<_AccountDetailSheet> {
  int _remaining = TotpService.secondsRemaining();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Own ticker so the sheet keeps counting down (and rotating the code)
    // independently of the list behind it.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = TotpService.secondsRemaining());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _code {
    final account = widget.account;
    if (account.secret.trim().isEmpty) {
      return account.code.isNotEmpty ? account.code : '------';
    }
    return TotpService.generateFormatted(account.secret);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            // Service avatar.
            Container(
              height: 72,
              width: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: account.avatarColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                account.initial,
                style: AppTextStyles.h1.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              account.name,
              style: AppTextStyles.h2.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: 4),
            Text(
              account.issuerEmail,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 24),
            // Large countdown ring.
            SizedBox(
              height: 88,
              width: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _remaining / 30,
                      strokeWidth: 4,
                      backgroundColor: AppColors.gray200,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.orange500,
                      ),
                    ),
                  ),
                  Text(
                    '$_remaining',
                    style: AppTextStyles.numberLarge.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // The live code, extra large.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _code,
                style: AppTextStyles.numberXXL.copyWith(
                  color: AppColors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Actions.
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: () => Navigator.of(context).pop(_DetailAction.edit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () => Navigator.of(context).pop(_DetailAction.copy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    destructive: true,
                    onTap: () =>
                        Navigator.of(context).pop(_DetailAction.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = destructive
        ? AppColors.errorBackground
        : AppColors.gray100;
    final Color foreground = destructive ? AppColors.error : AppColors.black;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 24, color: foreground),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmallSemiBold.copyWith(
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation bottom sheet shown before permanently deleting an account.
class _DeleteAccountSheet extends StatelessWidget {
  final Account account;

  const _DeleteAccountSheet({required this.account});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        margin: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 30,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Delete Account?',
              style: AppTextStyles.h2.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: 'Remove ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                children: [
                  TextSpan(
                    text: account.name,
                    style: AppTextStyles.bodyMediumSemiBold.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' from your accounts. You will lose access to its '
                        'codes. This cannot be undone.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Delete Account',
                        style: AppTextStyles.bodyMediumSemiBold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.orange500,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMediumSemiBold.copyWith(
                          color: AppColors.orange500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  final int remaining;

  const _CountdownRing({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: remaining / 30,
            strokeWidth: 2.4,
            backgroundColor: AppColors.gray200,
            valueColor: const AlwaysStoppedAnimation(AppColors.orange500),
          ),
          Text(
            '$remaining',
            style: AppTextStyles.numberSmall.copyWith(
              color: AppColors.gray500,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends StatelessWidget {
  const _AddAccountSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Account',
            style: AppTextStyles.h2.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'How would you like to add it?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 20),
          _AddOption(
            icon: 'assets/svg/QR.svg',
            iconBg: AppColors.orange500,
            background: AppColors.orange50,
            title: 'Scan QR Code',
            subtitle: 'Use your camera to scan',
            onTap: () => Navigator.of(context).pop(_AddMethod.scan),
          ),
          const SizedBox(height: 12),
          _AddOption(
            icon: 'assets/svg/keyboard.svg',
            iconBg: AppColors.black,
            background: AppColors.gray100,
            title: 'Enter Manually',
            subtitle: 'Type the secret key',
            onTap: () => Navigator.of(context).pop(_AddMethod.manual),
          ),
        ],
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.iconBg,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(icon),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMediumSemiBold.copyWith(
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
            ],
          ),
        ),
      ),
    );
  }
}
