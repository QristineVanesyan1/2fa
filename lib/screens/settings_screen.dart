import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/home_screen.dart';
import 'package:authenticator/screens/set_passcode_screen.dart';
import 'package:authenticator/services/biometric_auth.dart';
import 'package:authenticator/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen Settings page (with its own bottom navigation), used when the
/// settings are pushed onto the navigation stack (e.g. from the paywall).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _settingsIndex = 3;

  void _onNavChanged(int index) {
    // The standalone Settings screen only shows the Settings tab; selecting a
    // different tab takes the user into the home shell on that tab.
    if (index == _settingsIndex) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: const SafeArea(bottom: false, child: SettingsBody()),
      bottomNavigationBar: BottomNavBar(
        index: _settingsIndex,
        onChanged: _onNavChanged,
      ),
    );
  }
}

/// The scrollable settings content, without any Scaffold or bottom navigation,
/// so it can be embedded inside a host screen's tab.
class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  bool _passcodeLock = false;
  bool _faceId = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricAuth.isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
  }

  Future<void> _onPasscodeToggle(bool value) async {
    if (value) {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const SetPasscodeScreen()),
      );
      if (!mounted) return;
      setState(() => _passcodeLock = result != null && result.length == 4);
    } else {
      // Turning off the passcode also disables Face ID.
      setState(() {
        _passcodeLock = false;
        _faceId = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  // Face ID is available whenever the device supports biometrics.
  bool get _faceIdEnabled => _biometricAvailable;

  Future<void> _onFaceIdToggle(bool value) async {
    if (value) {
      final result = await BiometricAuth.authenticate(
        reason: 'Enable Face ID to unlock the app',
      );
      if (!mounted) return;
      setState(() => _faceId = result.success);
      if (!result.success && result.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.error!)));
      }
    } else {
      setState(() => _faceId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTextStyles.display.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Security'),
          const SizedBox(height: 10),
          _Card(
            children: [
              _SettingRow(
                icon: Icons.lock_outline,
                iconBg: AppColors.black,
                title: 'Passcode Lock',
                subtitle: 'Require passcode to open',
                trailing: Switch.adaptive(
                  value: _passcodeLock,
                  activeTrackColor: AppColors.orange500,
                  onChanged: _onPasscodeToggle,
                ),
              ),
              const _Divider(),
              _SettingRow(
                icon: Icons.fingerprint,
                iconBg: _faceIdEnabled
                    ? AppColors.orange500
                    : AppColors.gray400,
                title: 'Face ID',
                subtitle: _faceIdEnabled
                    ? 'Unlock with Face ID'
                    : 'Not available on this device',

                disabled: !_faceIdEnabled,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_faceIdEnabled) ...[
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Switch.adaptive(
                      value: _faceId,
                      activeTrackColor: AppColors.orange500,
                      onChanged: _faceIdEnabled ? _onFaceIdToggle : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionLabel('General'),
          const SizedBox(height: 10),
          _Card(
            children: [
              _SettingRow(
                icon: Icons.ios_share,
                iconBg: AppColors.blue,
                title: 'Share App',
                trailing: const _Chevron(),
                onTap: () {},
              ),
              const _Divider(),
              _SettingRow(
                icon: Icons.star_border,
                iconBg: AppColors.orange400,
                title: 'Rate Us',
                trailing: const _Chevron(),
                onTap: () {},
              ),
              const _Divider(),
              _SettingRow(
                icon: Icons.chat_bubble_outline,
                iconBg: AppColors.teal,
                title: 'Contact Support',
                trailing: const _Chevron(),
                onTap: () {},
              ),
              const _Divider(),
              _SettingRow(
                icon: Icons.description_outlined,
                iconBg: AppColors.blue,
                title: 'Terms of Use',
                trailing: const _Chevron(),
                onTap: () => _openUrl('https://google.com'),
              ),
              const _Divider(),
              _SettingRow(
                icon: Icons.privacy_tip_outlined,
                iconBg: AppColors.success,
                title: 'Privacy Policy',
                trailing: const _Chevron(),
                onTap: () => _openUrl('https://google.com'),
              ),

              const _Divider(),
              _SettingRow(
                icon: Icons.shopping_bag_outlined,
                iconBg: AppColors.orange500,
                title: 'Restore Purchase',
                trailing: const _Chevron(),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 1, color: AppColors.gray100),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool disabled;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = disabled ? AppColors.gray400 : AppColors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMediumSemiBold.copyWith(
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chevron_right, color: AppColors.gray400, size: 22);
  }
}
