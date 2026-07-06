import 'dart:async';

import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/account_local_data_source.dart';
import 'package:authenticator/data/password_local_data_source.dart';
import 'package:authenticator/models/account.dart';
import 'package:authenticator/models/password_entry.dart';
import 'package:authenticator/screens/add_manually_screen.dart';
import 'package:authenticator/screens/add_password_screen.dart';
import 'package:authenticator/screens/browser_screen.dart';
import 'package:authenticator/screens/scan_qr_screen.dart';
import 'package:authenticator/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seed data used the first time the app runs so the list isn't empty.
const _demoAccounts = <Account>[
  Account(
    name: 'GitHub',
    issuerEmail: 'alice@dev.io',
    code: '482 091',
    avatarColor: AppColors.black,
  ),
  Account(
    name: 'Google',
    issuerEmail: 'alice@gmail.com',
    code: '613 007',
    avatarColor: AppColors.orange500,
  ),
  Account(
    name: 'Stripe',
    issuerEmail: 'alice@company.com',
    code: '185 148',
    avatarColor: AppColors.blue,
  ),
  Account(
    name: 'AWS',
    issuerEmail: 'root@company-aws.com',
    code: '633 789',
    avatarColor: AppColors.orange400,
  ),
  Account(
    name: 'Figma',
    issuerEmail: 'alice@design.io',
    code: '424 521',
    avatarColor: AppColors.red,
  ),
];

class CodesScreen extends StatefulWidget {
  /// When true the screen renders the empty ("Nothing here yet") state.
  final bool showEmpty;

  const CodesScreen({super.key, this.showEmpty = false});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Separate local data sources for accounts and passwords.
  final AccountLocalDataSource _accountsDataSource =
      SharedPrefsAccountLocalDataSource();
  final PasswordLocalDataSource _passwordsDataSource =
      SharedPrefsPasswordLocalDataSource();

  int _navIndex = 0;
  String _query = '';

  List<Account> _accounts = [];
  List<PasswordEntry> _passwords = [];

  // Countdown seconds shared by every code (TOTP style 30s window).
  int _remaining = 22;
  Timer? _timer;

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

  List<PasswordEntry> get _filteredPasswords {
    if (_query.isEmpty) return _passwords;
    final q = _query.toLowerCase();
    return _passwords
        .where(
          (p) =>
              p.service.toLowerCase().contains(q) ||
              p.account.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _remaining <= 1 ? 30 : _remaining - 1);
    });
  }

  /// Loads accounts and passwords from their local data sources.
  Future<void> _load() async {
    var accounts = await _accountsDataSource.getAccounts();
    // Seed with demo accounts on first run so the list isn't empty.
    if (accounts.isEmpty && !widget.showEmpty) {
      await _accountsDataSource.saveAccounts(_demoAccounts);
      accounts = _demoAccounts;
    }
    final passwords = await _passwordsDataSource.getPasswords();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _passwords = passwords;
    });
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

  Future<void> _openAddPassword() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddPasswordScreen()));
    // Reload to reflect any newly saved password.
    await _load();
  }

  void _onAddPressed() {
    // On the Passwords tab the "+" goes straight to the Add Password screen.
    if (_navIndex == 1) {
      _openAddPassword();
    } else {
      _showAddAccountSheet();
    }
  }

  void _copyCode(Account account) {
    Clipboard.setData(ClipboardData(text: account.code.replaceAll(' ', '')));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${account.name} code copied'),
        ),
      );
  }

  void _copyPassword(PasswordEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.password));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('${entry.service} password copied'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isBrowser = _navIndex == 2;
    final isSettings = _navIndex == 3;
    final showFab = !isBrowser && !isSettings;
    return Scaffold(
      backgroundColor: AppColors.base,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _onAddPressed,
              backgroundColor: AppColors.orange500,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: AppColors.white, size: 30),
            )
          : null,
      body: SafeArea(bottom: false, child: _buildBody(isBrowser, isSettings)),
      bottomNavigationBar: _BottomNavBar(
        index: _navIndex,
        onChanged: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildBody(bool isBrowser, bool isSettings) {
    if (isBrowser) return const BrowserScreen();
    if (isSettings) return const SettingsBody();
    if (_navIndex == 1) return _buildPasswordsBody();
    return _buildCodesBody();
  }

  Widget _buildCodesBody() {
    final accounts = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authenticator',
                style: AppTextStyles.display.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 4),
              Text(
                '${_accounts.length} accounts',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 16),
              _SearchField(
                controller: _searchController,
                hintText: 'Search accounts...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? const _EmptyState(
                  title: 'Nothing here yet',
                  subtitle:
                      'Add your first account manually\nor scan a QR code',
                  icon: Icons.fingerprint,
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
                    remaining: _remaining,
                    onCopy: () => _copyCode(accounts[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordsBody() {
    final passwords = _filteredPasswords;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passwords',
                style: AppTextStyles.display.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 4),
              Text(
                '${_passwords.length} passwords',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 16),
              _SearchField(
                controller: _searchController,
                hintText: 'Search passwords...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: passwords.isEmpty
              ? const _EmptyState(
                  title: 'No passwords yet',
                  subtitle: 'Tap + to save your first password',
                  icon: Icons.key,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  itemCount: passwords.length,
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.gray200,
                    ),
                  ),
                  itemBuilder: (_, i) => _PasswordRow(
                    entry: passwords[i],
                    onCopy: () => _copyPassword(passwords[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.gray500, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final int remaining;
  final VoidCallback onCopy;

  const _AccountRow({
    required this.account,
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
            account.code,
            style: AppTextStyles.numberLarge.copyWith(color: AppColors.black),
          ),
          const SizedBox(width: 10),
          _CountdownRing(remaining: remaining),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onCopy;

  const _PasswordRow({required this.entry, required this.onCopy});

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
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.initial,
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
                  entry.service,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.account,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '••••••••',
            style: AppTextStyles.numberMedium.copyWith(
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: AppColors.gray500,
            ),
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

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
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
            icon: Icons.qr_code_2,
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
            icon: Icons.keyboard_alt_outlined,
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
  final IconData icon;
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
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
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

class _BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNavBar({required this.index, required this.onChanged});

  static const _items = [
    (Icons.qr_code_2, 'Codes'),
    (Icons.key, 'Passwords'),
    (Icons.public, 'Browser'),
    (Icons.settings, 'Settings'),
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
            children: List.generate(_items.length, (i) {
              final active = i == index;
              final item = _items[i];
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
                        Icon(
                          item.$1,
                          size: 20,
                          color: active ? AppColors.black : AppColors.gray400,
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
