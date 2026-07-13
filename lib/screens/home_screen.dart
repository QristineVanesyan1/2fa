import 'package:authenticator/const/colors.dart';
import 'package:authenticator/screens/browser_screen.dart';
import 'package:authenticator/screens/codes_screen.dart';
import 'package:authenticator/screens/passwords_screen.dart';
import 'package:authenticator/screens/settings_screen.dart';
import 'package:authenticator/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// Home shell that hosts the four tabs and owns the bottom navigation.
///
/// Each tab is a standalone screen (Codes, Passwords, Browser, Settings) — the
/// shell just swaps the active screen and keeps the shared [BottomNavBar] in
/// sync with the selected index.
class HomeScreen extends StatefulWidget {
  /// Forwarded to the tabs so they can render their empty states (used in tests
  /// / previews).
  final bool showEmpty;

  /// Tab to show first (0: Codes, 1: Passwords, 2: Browser, 3: Settings).
  final int initialIndex;

  const HomeScreen({super.key, this.showEmpty = false, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _navIndex = widget.initialIndex;

  Widget _screenFor(int index) {
    switch (index) {
      case 1:
        return PasswordsScreen(showEmpty: widget.showEmpty);
      case 2:
        return const _TabScaffold(child: BrowserScreen());
      case 3:
        return const _TabScaffold(child: SettingsBody());
      case 0:
      default:
        return CodesScreen(showEmpty: widget.showEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.base,
      body: _screenFor(_navIndex),
      bottomNavigationBar: BottomNavBar(
        index: _navIndex,
        onChanged: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

/// Wraps tabs that render plain content (no Scaffold of their own) so they get
/// a consistent background and safe-area handling inside the shell.
class _TabScaffold extends StatelessWidget {
  final Widget child;

  const _TabScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.base,
      body: SafeArea(bottom: false, child: child),
    );
  }
}
