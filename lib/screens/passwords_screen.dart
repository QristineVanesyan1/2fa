import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/data/password_local_data_source.dart';
import 'package:authenticator/models/password_entry.dart';
import 'package:authenticator/screens/add_password_screen.dart';
import 'package:authenticator/widgets/custom_toast.dart';
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
    CustomToast.show(context, message: '${entry.service} password copied');
  }

  /// Opens the detail bottom sheet for [entry].
  ///
  /// The sheet exposes view / copy / edit / delete actions. Because filtering
  /// can reorder the visible list, we resolve the entry's real index in the
  /// underlying [_passwords] list before mutating it.
  Future<void> _openDetails(PasswordEntry entry) async {
    final action = await showModalBottomSheet<_DetailAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PasswordDetailSheet(entry: entry),
    );

    if (!mounted || action == null) return;

    final index = _passwords.indexOf(entry);
    if (index < 0) return;

    switch (action) {
      case _DetailAction.copy:
        _copyPassword(entry);
        break;
      case _DetailAction.edit:
        await _editPassword(entry, index);
        break;
      case _DetailAction.delete:
        await _confirmDelete(entry, index);
        break;
    }
  }

  Future<void> _editPassword(PasswordEntry entry, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AddPasswordScreen(entry: entry, editIndex: index),
      ),
    );
    await _load();
  }

  Future<void> _confirmDelete(PasswordEntry entry, int index) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.overlay,
      builder: (_) => _DeletePasswordSheet(entry: entry),
    );

    if (!mounted || confirmed != true) return;

    await _passwordsDataSource.deletePassword(index);
    await _load();
    if (!mounted) return;
    CustomToast.show(context, message: '${entry.service} password deleted');
  }

  @override
  Widget build(BuildContext context) {
    final passwords = _filtered;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  ? EmptyState(
                      title: 'No passwords yet',
                      subtitle: 'Tap + to save your first password',
                      icon: "assets/images/empty2.png",
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
                        onTap: () => _openDetails(passwords[i]),
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
  final VoidCallback onTap;

  const _PasswordRow({
    required this.entry,
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
      ),
    );
  }
}

/// Actions the detail bottom sheet can return to its opener.
enum _DetailAction { copy, edit, delete }

/// Bottom sheet showing a single password's details with reveal, strength
/// indicator and Edit / Copy / Delete actions.
class _PasswordDetailSheet extends StatefulWidget {
  final PasswordEntry entry;

  const _PasswordDetailSheet({required this.entry});

  @override
  State<_PasswordDetailSheet> createState() => _PasswordDetailSheetState();
}

class _PasswordDetailSheetState extends State<_PasswordDetailSheet> {
  bool _revealed = false;

  /// Strength on a 0..1 scale from length + character variety.
  double get _strength {
    final pwd = widget.entry.password;
    if (pwd.isEmpty) return 0;
    var score = 0.0;
    if (pwd.length >= 8) score += 0.25;
    if (pwd.length >= 12) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) score += 0.20;
    return score.clamp(0.0, 1.0);
  }

  ({String label, Color color, int segments}) get _strengthInfo {
    if (_strength >= 0.8) {
      return (label: 'Strong', color: AppColors.success, segments: 3);
    }
    if (_strength >= 0.5) {
      return (label: 'Medium', color: AppColors.orange500, segments: 2);
    }
    return (label: 'Weak', color: AppColors.error, segments: 1);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final info = _strengthInfo;
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
                color: AppColors.info,
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
                color: AppColors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.initial,
                style: AppTextStyles.h1.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              entry.service,
              style: AppTextStyles.h2.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: 4),
            Text(
              entry.account,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 20),
            // Password reveal + strength card.
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _revealed ? entry.password : '••••••••••••••',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.numberLarge.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () =>
                              setState(() => _revealed = !_revealed),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _revealed ? Icons.visibility_off : Icons.visibility,
                            size: 22,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
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
                                  color: active
                                      ? info.color
                                      : AppColors.gray200,
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
                        style: AppTextStyles.bodySmallSemiBold.copyWith(
                          color: info.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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

/// Confirmation bottom sheet shown before permanently deleting a password.
class _DeletePasswordSheet extends StatelessWidget {
  final PasswordEntry entry;

  const _DeletePasswordSheet({required this.entry});

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
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

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
              'Delete Password?',
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
                    text: entry.service,
                    style: AppTextStyles.bodyMediumSemiBold.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const TextSpan(
                    text: ' from your passwords. This cannot be undone.',
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
                        'Delete Password',
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
