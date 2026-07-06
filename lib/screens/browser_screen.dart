import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Private in-app browser surface with three states:
///   - start page ("Browse privately")
///   - loaded page (renders the requested URL)
///   - error page ("Can't reach this page")
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _urlController = TextEditingController();

  // Session history so back/forward behave naturally.
  final List<String> _history = <String>[];
  int _index = -1;

  String? get _url =>
      (_index >= 0 && _index < _history.length) ? _history[_index] : null;

  bool get _hasPage => _url != null;
  bool get _canGoBack => _index > 0;
  bool get _canGoForward => _index < _history.length - 1;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _normalize(String input) {
    var url = input.trim();
    if (url.isEmpty) return null;
    if (url.contains(' ') || !url.contains('.')) {
      return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(url)}';
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  void _load(String input) {
    final url = _normalize(input);
    if (url == null) return;
    setState(() {
      if (_index < _history.length - 1) {
        _history.removeRange(_index + 1, _history.length);
      }
      _history.add(url);
      _index = _history.length - 1;
      _urlController.text = url;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pasteAndLoad() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _load(text);
    }
  }

  void _goBack() {
    if (!_canGoBack) return;
    setState(() {
      _index--;
      _urlController.text = _url ?? '';
    });
  }

  void _goForward() {
    if (!_canGoForward) return;
    setState(() {
      _index++;
      _urlController.text = _url ?? '';
    });
  }

  void _reload() => setState(() {});

  void _endSession() {
    setState(() {
      _history.clear();
      _index = -1;
      _urlController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _clearUrl() {
    setState(() {
      _history.clear();
      _index = -1;
      _urlController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Browser',
            style: AppTextStyles.display.copyWith(color: AppColors.black),
          ),
        ),
        _AddressBar(
          controller: _urlController,
          hasPage: _hasPage,
          onSubmit: _load,
          onPaste: _pasteAndLoad,
          onClear: _clearUrl,
        ),
        _ToolBar(
          canGoBack: _canGoBack,
          canGoForward: _canGoForward,
          active: _hasPage,
          onBack: _goBack,
          onForward: _goForward,
          onReload: _reload,
          onEndSession: _endSession,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _hasPage
                ? _PageView(url: _url!)
                : _StartPage(onPaste: _pasteAndLoad),
          ),
        ),
      ],
    );
  }
}

class _AddressBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasPage;
  final ValueChanged<String> onSubmit;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  const _AddressBar({
    required this.controller,
    required this.hasPage,
    required this.onSubmit,
    required this.onPaste,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const _PrivateBadge(),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.go,
                onSubmitted: onSubmit,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'Paste or type a URL...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (hasPage)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 24,
                  width: 24,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.gray300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 15,
                    color: AppColors.white,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onPaste,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: Text(
                    'Paste',
                    style: AppTextStyles.bodySmallSemiBold.copyWith(
                      color: AppColors.orange500,
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

class _PrivateBadge extends StatelessWidget {
  const _PrivateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 14,
            color: AppColors.gray500,
          ),
          const SizedBox(width: 5),
          Text(
            'Private',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final bool active;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onEndSession;

  const _ToolBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.active,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onEndSession,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new,
            enabled: canGoBack,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          _CircleButton(
            icon: Icons.arrow_forward_ios,
            enabled: canGoForward,
            onTap: onForward,
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.refresh, enabled: active, onTap: onReload),
          const Spacer(),
          GestureDetector(
            onTap: active ? onEndSession : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout,
                  size: 18,
                  color: active ? AppColors.orange500 : AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  'End session',
                  style: AppTextStyles.bodySmallSemiBold.copyWith(
                    color: active ? AppColors.orange500 : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.black : AppColors.gray200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.white : AppColors.gray400,
        ),
      ),
    );
  }
}

class _StartPage extends StatelessWidget {
  final VoidCallback onPaste;

  const _StartPage({required this.onPaste});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            child: const Icon(
              Icons.travel_explore,
              size: 60,
              color: AppColors.orange500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Browse privately',
            style: AppTextStyles.h3.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'No history saved. Your session clears\n'
            'automatically when you leave.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          Material(
            color: AppColors.orange500,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              onTap: onPaste,
              borderRadius: BorderRadius.circular(26),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                child: Text(
                  'Paste a link',
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: AppColors.white,
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

class _PageView extends StatelessWidget {
  final String url;

  const _PageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: AppColors.card,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const _LoadingPage();
          },
          errorBuilder: (context, error, stack) => const _ErrorPage(),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation(AppColors.orange500),
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: AppColors.errorBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Can't reach this page",
            style: AppTextStyles.h3.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Check that the URL is correct and try\nagain.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
