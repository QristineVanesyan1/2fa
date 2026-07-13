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
  static const Set<String> _staticDemoSignatures = {
    'GitHub|alice@dev.io|482 091',
    'Google|alice@gmail.com|613 007',
    'Stripe|alice@company.com|185 148',
    'AWS|root@company-aws.com|633 789',
    'Figma|alice@design.io|424 521',
  };

  // Demo accounts backed by real Base32 secrets so the generated codes rotate
  // every 30 seconds, exactly like Google Authenticator.
  static const List<Account> _demoAccounts = [
    Account(
      name: 'GitHub',
      issuerEmail: 'alice@dev.io',
      secret: 'JBSWY3DPEHPK3PXP',
      avatarColor: AppColors.black,
    ),
    Account(
      name: 'Google',
      issuerEmail: 'alice@gmail.com',
      secret: 'KVKFKRCPNZQUYMLXOVYDSQKJKZDTSRLD',
      avatarColor: AppColors.orange500,
    ),
    Account(
      name: 'Stripe',
      issuerEmail: 'alice@company.com',
      secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
      avatarColor: AppColors.blue,
    ),
    Account(
      name: 'AWS',
      issuerEmail: 'root@company-aws.com',
      secret: 'NB2W45DFOIZA====',
      avatarColor: AppColors.orange400,
    ),
    Account(
      name: 'Figma',
      issuerEmail: 'alice@design.io',
      secret: 'MFRGGZDFMZTWQ2LK',
      avatarColor: AppColors.red,
    ),
  ];

  Future<void> _load() async {
    if (widget.showEmpty) {
      if (!mounted) return;
      setState(() => _accounts = []);
      return;
    }
    var accounts = await _accountsDataSource.getAccounts();

    // Migrate away from the old static demo accounts (code, but no secret).
    final cleaned = accounts
        .where(
          (a) => !_staticDemoSignatures.contains(
            '${a.name}|${a.issuerEmail}|${a.code}',
          ),
        )
        .toList();

    // Seed the secret-backed demo accounts on a fresh install so the tab shows
    // live, rotating codes out of the box.
    if (cleaned.isEmpty) {
      cleaned.addAll(_demoAccounts);
    }

    if (cleaned.length != accounts.length) {
      await _accountsDataSource.saveAccounts(cleaned);
      accounts = cleaned;
    }
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddAccountSheet(),
    );
    // Reload in case a new account was persisted while the sheet was open.
    await _load();
  }

  void _copyCode(Account account) {
    final code = _codeFor(account).replaceAll(' ', '');
    Clipboard.setData(ClipboardData(text: code));
    CustomToast.show(context, message: '${account.name} code copied');
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filtered;
    return Scaffold(
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
                          'Add your first account manually\nor scan a QR code',
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

  const _AccountRow({
    required this.account,
    required this.code,
    required this.remaining,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ScanQrScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _AddOption(
            icon: 'assets/svg/keyboard.svg',
            iconBg: AppColors.black,
            background: AppColors.gray100,
            title: 'Enter Manually',
            subtitle: 'Type the secret key',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddManuallyScreen(),
                ),
              );
            },
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
