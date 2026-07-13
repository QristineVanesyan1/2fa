import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/add_manually_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Full-screen QR code scanner used to add a 2FA account by scanning an
/// `otpauth://` URI. On a successful scan the parsed values are forwarded to
/// [AddManuallyScreen] for review before saving.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _handled = false;

  void _onViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final raw = scanData.code;
      if (_handled || raw == null || raw.isEmpty) return;
      final parsed = _parseOtpAuth(raw);
      if (parsed != null) {
        _handled = true;
        if (!mounted) return;
        final navigator = Navigator.of(context);
        await controller.pauseCamera();
        // Push (not replace) so this route stays on the stack; once the user
        // finishes adding, we pop back to the Codes screen which then reloads.
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => AddManuallyScreen(
              initialService: parsed.issuer,
              initialAccount: parsed.account,
              initialSecret: parsed.secret,
            ),
          ),
        );
        navigator.pop();
      }
    });
  }

  /// Parses an `otpauth://totp/Issuer:account?secret=...&issuer=...` URI.
  _OtpData? _parseOtpAuth(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'otpauth') return null;

    final secret = uri.queryParameters['secret'];
    if (secret == null || secret.isEmpty) return null;

    // Label is the path, e.g. "/GitHub:alice@dev.io".
    final label = Uri.decodeComponent(
      uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
    );

    String? issuer = uri.queryParameters['issuer'];
    String account = label;
    if (label.contains(':')) {
      final parts = label.split(':');
      issuer ??= parts.first.trim();
      account = parts.sublist(1).join(':').trim();
    }

    return _OtpData(
      issuer: issuer?.trim(),
      account: account.trim(),
      secret: secret.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Container(
            decoration: BoxDecoration(
              color: AppColors.gray10,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset("assets/images/arrow_left.svg"),
          ),
        ),
        centerTitle: false,
        title: Text(
          'Scan QR Code',
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller?.toggleFlash(),
            icon: Container(
              decoration: BoxDecoration(
                color: AppColors.gray10,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset("assets/images/Flash.svg"),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(
              bottom: MediaQuery.of(context).size.height / 4,
            ),
            child: QRView(
              key: _qrKey,
              onQRViewCreated: _onViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.orange500,
                borderRadius: 24,
                borderLength: 32,
                borderWidth: 6,
              ),
            ),
          ),

          Positioned(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height / 4,
                width: double.infinity,
                color: AppColors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Align the QR code within the frame',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        splashFactory: NoSplash.splashFactory,
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await _controller?.pauseCamera();
                        await navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AddManuallyScreen(),
                          ),
                        );
                        navigator.pop();
                      },

                      child: Text(
                        'Enter manually instead',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.orange500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpData {
  final String? issuer;
  final String account;
  final String secret;

  const _OtpData({
    required this.issuer,
    required this.account,
    required this.secret,
  });
}
