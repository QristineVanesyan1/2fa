import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Private in-app browser surface with three states:
///   - start page ("Browse privately")
///   - loaded page (renders the requested URL in a real WebView)
///   - error page ("Can't reach this page")
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _urlController = TextEditingController();

  late final WebViewController _controller;

  bool _hasPage = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.card)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              if (url.isNotEmpty && url != 'about:blank') {
                _urlController.text = url;
              }
            });
            await _updateNavState();
          },
          onWebResourceError: (error) {
            // Ignore errors for subframes/other resources; only fail the
            // main page load.
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      );
  }

  Future<void> _updateNavState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

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
      _hasPage = true;
      _hasError = false;
      _isLoading = true;
      _urlController.text = url;
    });
    _controller.loadRequest(Uri.parse(url));
    FocusScope.of(context).unfocus();
  }

  Future<void> _pasteAndLoad() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _load(text);
    }
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      await _updateNavState();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
      await _updateNavState();
    }
  }

  void _reload() => _controller.reload();

  void _endSession() {
    _controller.clearCache();
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _hasPage = false;
      _hasError = false;
      _isLoading = false;
      _canGoBack = false;
      _canGoForward = false;
      _urlController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _clearUrl() {
    _controller.loadRequest(Uri.parse('about:blank'));
    setState(() {
      _hasPage = false;
      _hasError = false;
      _isLoading = false;
      _canGoBack = false;
      _canGoForward = false;
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
                ? _PageView(
                    controller: _controller,
                    isLoading: _isLoading,
                    hasError: _hasError,
                  )
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
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
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
            icon: 'assets/svg/arrow_left.svg',
            enabled: canGoBack,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          _CircleButton(
            icon: 'assets/svg/arrow_right.svg',
            enabled: canGoForward,
            onTap: onForward,
          ),
          const SizedBox(width: 10),
          _CircleButton(
            icon: 'assets/svg/Generate.svg',
            enabled: active,
            onTap: onReload,
          ),
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
  final String icon;
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
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          icon,
          colorFilter: ColorFilter.mode(
            enabled ? AppColors.black : AppColors.gray400,
            BlendMode.srcIn,
          ),
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
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
              height: 160,
              width: 160,
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
              child: Image.asset("assets/images/empty3.png"),
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
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final WebViewController controller;
  final bool isLoading;
  final bool hasError;

  const _PageView({
    required this.controller,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: AppColors.card,
        width: double.infinity,
        child: hasError
            ? const _ErrorPage()
            : Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (isLoading) const _LoadingPage(),
                ],
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
