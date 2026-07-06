import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/password_local_data_source.dart';
import 'package:authenticator/models/password_entry.dart';
import 'package:authenticator/screens/add_password_screen.dart';
import 'package:authenticator/widgets/empty_state.dart';
import 'package:authenticator/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standalone Passwords tab: lists saved passwords and lets the user add more.
class PasswordsScreen extends StatefulWidget {
  /// When true the screen renders the empty ("No passwords yet") state.
  final bool showEmpty;

  const PasswordsScreen({super.key, this.showEmpty = false});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PasswordLocalDataSource _passwordsDataSource =
      SharedPrefsPasswordLocalDataSource();

  String _query = '';
  List<PasswordEntry> _passwords = [];

  List<PasswordEntry> get _filtered {
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
  }

  Future<void> _load() async {
    if (widget.showEmpty) {
      if (!mounted) return;
      setState(() => _passwords = []);
      return;
    }
    final passwords = await _passwordsDataSource.getPasswords();
    if (!mounted) return;
    setState(() => _passwords = passwords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddPassword() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddPasswordScreen()));
    // Reload to reflect any newly saved password.
    await _load();
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
    final passwords = _filtered;
    return Scaffold(
      backgroundColor: AppColors.base,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPassword,
        backgroundColor: AppColors.orange500,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.white, size: 30),
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
                    'Passwords',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_passwords.length} passwords',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SearchField(
                    controller: _searchController,
                    hintText: 'Search passwords...',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: passwords.isEmpty
                  ? const EmptyState(
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
        ),
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
